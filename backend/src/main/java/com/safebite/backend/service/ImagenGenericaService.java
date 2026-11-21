package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.net.URI;
import java.text.Normalizer;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Imagen genérica (sin marca) de un tipo de alimento: "harina de arroz",
 * "pan", "galletitas". Se toma la foto principal del artículo de Wikipedia
 * de ese alimento, que muestra el producto en sí y no un envase comercial.
 *
 * Primero se busca el artículo en inglés con el término que propone la IA
 * (ej: "Rice flour"), que es la Wikipedia con más fotos; si no hay, se busca
 * en español o portugués con el nombre del tipo de producto, sin los sellos
 * ("sin TACC", "sem lactose"...). Si no aparece una foto, se devuelve vacío
 * y la app muestra un ícono: es preferible a mostrar una imagen equivocada.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ImagenGenericaService {

    private static final long CACHE_MS = 7L * 24 * 60 * 60 * 1000;
    private static final long FALLO_MS = 30L * 60 * 1000;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private record Entrada(long vence, String url) {}

    private final Map<String, Entrada> cache = new ConcurrentHashMap<>();

    /**
     * @param ingles  título o término en inglés (ej: "Rice flour"), puede ser null
     * @param local   tipo de producto en el idioma de la app (ej: "harina de arroz sin TACC")
     * @param pt      true si [local] está en portugués
     */
    public Optional<String> buscar(String ingles, String local, boolean pt) {
        String clave = (ingles == null ? "" : ingles.trim().toLowerCase()) + "|" + (local == null ? "" : local.trim().toLowerCase());
        if (clave.equals("|")) return Optional.empty();
        Entrada e = cache.get(clave);
        if (e != null && e.vence() > System.currentTimeMillis()) return Optional.ofNullable(e.url());

        String url = null;
        if (ingles != null && !ingles.isBlank()) {
            url = resumen("en", ingles.trim());
            if (url == null) url = buscarEnWiki("en", ingles.trim());
        }
        String generico = sinSellos(local);
        if (url == null && !generico.isBlank()) {
            String wiki = pt ? "pt" : "es";
            url = resumen(wiki, generico);
            if (url == null) url = buscarEnWiki(wiki, generico);
        }
        cache.put(clave, new Entrada(System.currentTimeMillis() + (url != null ? CACHE_MS : FALLO_MS), url));
        return Optional.ofNullable(url);
    }

    /** Foto principal del artículo con ese título exacto (no sirve si es una página de desambiguación). */
    private String resumen(String wiki, String titulo) {
        try {
            String t = titulo.substring(0, 1).toUpperCase() + titulo.substring(1);
            URI uri = UriComponentsBuilder.fromHttpUrl("https://" + wiki + ".wikipedia.org/api/rest_v1/page/summary/{t}")
                    .buildAndExpand(t.replace(' ', '_')).encode().toUri();
            JsonNode raiz = pedir(uri);
            if (raiz == null || "disambiguation".equals(raiz.path("type").asText())) return null;
            return valida(raiz.path("thumbnail").path("source").asText(null));
        } catch (Exception ex) {
            log.debug("Wikipedia {} sin resumen para '{}': {}", wiki, titulo, ex.getMessage());
            return null;
        }
    }

    /** Búsqueda en la Wikipedia: primer artículo con foto entre los tres más relevantes. */
    private String buscarEnWiki(String wiki, String termino) {
        try {
            URI uri = UriComponentsBuilder.fromHttpUrl("https://" + wiki + ".wikipedia.org/w/api.php")
                    .queryParam("action", "query")
                    .queryParam("format", "json")
                    .queryParam("generator", "search")
                    .queryParam("gsrsearch", termino)
                    .queryParam("gsrnamespace", 0)
                    .queryParam("gsrlimit", 3)
                    .queryParam("prop", "pageimages")
                    .queryParam("piprop", "thumbnail")
                    .queryParam("pithumbsize", 320)
                    .build().encode().toUri();
            JsonNode raiz = pedir(uri);
            if (raiz == null) return null;
            JsonNode paginas = raiz.path("query").path("pages");
            String mejor = null;
            int mejorIndice = Integer.MAX_VALUE;
            for (JsonNode p : paginas) {
                String u = valida(p.path("thumbnail").path("source").asText(null));
                int indice = p.path("index").asInt(99);
                if (u != null && indice < mejorIndice) {
                    mejor = u;
                    mejorIndice = indice;
                }
            }
            return mejor;
        } catch (Exception ex) {
            log.debug("Búsqueda en Wikipedia {} falló para '{}': {}", wiki, termino, ex.getMessage());
            return null;
        }
    }

    private JsonNode pedir(URI uri) throws Exception {
        HttpHeaders h = new HttpHeaders();
        // Wikimedia pide identificar la aplicación en el User-Agent.
        h.set(HttpHeaders.USER_AGENT, "SafeBite/1.0 (app de restricciones alimentarias; TCC IFSul)");
        ResponseEntity<String> r = restTemplate.exchange(uri, HttpMethod.GET, new HttpEntity<>(h), String.class);
        return r.getBody() == null ? null : objectMapper.readTree(r.getBody());
    }

    /** Descarta logos, mapas y dibujos (svg): para un alimento se quiere una foto. */
    private static String valida(String url) {
        if (url == null || !url.startsWith("http")) return null;
        String u = url.toLowerCase();
        for (String malo : List.of(".svg", "logo", "_map", "map_", "_mapa", "mapa_", "flag_", "bandera", "icon")) {
            if (u.contains(malo)) return null;
        }
        return url;
    }

    /** Quita los sellos y aclaraciones para quedarse con el tipo de alimento: "pan sin TACC" -> "pan". */
    static String sinSellos(String texto) {
        if (texto == null) return "";
        String t = " " + texto.toLowerCase() + " ";
        for (String sello : List.of(" sin tacc", " sin gluten", " sin lactosa", " sin leche", " sin huevo", " sin azucar",
                " sin azúcar", " sem glúten", " sem gluten", " sem lactose", " sem leite", " sem ovo", " sem açúcar",
                " zero lactose", " libre de gluten", " livre de glúten", " vegano", " vegana", " veganos", " veganas",
                " apto celíacos", " apto celiacos", " para celíacos", " para celiacos", " sin frutos secos", " sem castanhas")) {
            t = t.replace(sello + " ", " ");
        }
        t = t.replaceAll("\\s+", " ").trim();
        return Normalizer.normalize(t, Normalizer.Form.NFC);
    }
}

package com.safebite.backend.service;

import com.safebite.backend.model.TipoIntolerancia;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.concurrent.ConcurrentHashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class OpenFoodFactsService {

    private static final String BASE_URL = "https://world.openfoodfacts.org/api/v2/product/";
    private static final String FIELDS = "product_name,brands,image_url,ingredients_text,allergens_tags,traces_tags";

    private final RestTemplate restTemplate;
    private final AlergenoTextAnalyzer alergenoTextAnalyzer;

    public record ProductoExterno(
            String nombre,
            String marca,
            String imagenUrl,
            List<String> ingredientes,
            Set<TipoIntolerancia> alergenos
    ) {}

    @SuppressWarnings("unchecked")
    public Optional<ProductoExterno> buscarPorEan(String codigoEan) {
        String url = BASE_URL + codigoEan + ".json?fields=" + FIELDS;

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "SafeBiteApp/1.0 (contacto@safebite.com)");
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, entity, Map.class);
            Map<String, Object> body = response.getBody();

            if (body == null || !"1".equals(String.valueOf(body.get("status")))) {
                return Optional.empty();
            }

            Map<String, Object> producto = (Map<String, Object>) body.get("product");
            if (producto == null) {
                return Optional.empty();
            }

            String nombre = (String) producto.get("product_name");
            if (nombre == null || nombre.isBlank()) {
                return Optional.empty();
            }

            String marca = (String) producto.get("brands");
            String imagenUrl = (String) producto.get("image_url");
            String ingredientesTexto = (String) producto.get("ingredients_text");

            List<String> ingredientes = new ArrayList<>();
            if (ingredientesTexto != null && !ingredientesTexto.isBlank()) {
                for (String parte : ingredientesTexto.split(",")) {
                    String limpio = parte.trim();
                    if (!limpio.isEmpty()) ingredientes.add(limpio);
                }
            }

            List<String> tagsAlergenos = (List<String>) producto.getOrDefault("allergens_tags", List.of());
            Set<TipoIntolerancia> alergenos = new java.util.HashSet<>(mapearAlergenos(tagsAlergenos));

            List<String> tagsTrazas = (List<String>) producto.getOrDefault("traces_tags", List.of());
            alergenos.addAll(mapearAlergenos(tagsTrazas));

            alergenos.addAll(alergenoTextAnalyzer.detectar(ingredientesTexto));

            return Optional.of(new ProductoExterno(nombre, marca, imagenUrl, ingredientes, alergenos));

        } catch (Exception e) {
            log.warn("No se pudo consultar Open Food Facts para el EAN {}: {}", codigoEan, e.getMessage());
            return Optional.empty();
        }
    }

    // ---------- Busqueda de productos similares (recomendaciones) ----------

    private static final String SEARCH_URL = "https://world.openfoodfacts.org/cgi/search.pl";
    private static final String SEARCH_FIELDS =
            "code,product_name,brands,image_small_url,ingredients_text,allergens_tags,traces_tags";
    private static final long CACHE_MS = 24L * 60 * 60 * 1000;

    public record ProductoSimilar(
            String ean,
            String nombre,
            String marca,
            String pais,
            String imagenUrl,
            String ingredientesTexto,
            Set<TipoIntolerancia> alergenos
    ) {}

    private record EntradaCache(long vence, List<ProductoSimilar> productos) {}

    private final Map<String, EntradaCache> cacheSimilares = new ConcurrentHashMap<>();
    /** Busquedas fallidas recientes: no se reintentan por un rato para no insistirle a un servicio caido. */
    private final Map<String, Long> fallosRecientes = new ConcurrentHashMap<>();
    private static final long PAUSA_FALLO_MS = 3L * 60 * 1000;
    private static final long SEPARACION_MS = 1200;
    private final Object cerrojoBusqueda = new Object();
    private long ultimaBusquedaMs = 0;

    /**
     * Busca en Open Food Facts productos de un pais (tag: uruguay, argentina,
     * brazil) que coincidan con un termino. Solo devuelve los que tienen lista
     * de ingredientes (sin datos no se puede afirmar que sean seguros).
     * Los resultados se cachean 24 h porque la busqueda de OFF tiene limite
     * de consultas por minuto.
     */
    @SuppressWarnings("unchecked")
    public List<ProductoSimilar> buscarSimilares(String termino, String paisTag) {
        if (termino == null || termino.isBlank()) return List.of();
        String clave = paisTag + "|" + termino.trim().toLowerCase();
        EntradaCache cacheado = cacheSimilares.get(clave);
        if (cacheado != null && cacheado.vence() > System.currentTimeMillis()) {
            return cacheado.productos();
        }

        Long falloHasta = fallosRecientes.get(clave);
        if (falloHasta != null && falloHasta > System.currentTimeMillis()) {
            return List.of();
        }

        try {
            String url = UriComponentsBuilder.fromHttpUrl(SEARCH_URL)
                    .queryParam("search_terms", termino.trim())
                    .queryParam("search_simple", 1)
                    .queryParam("action", "process")
                    .queryParam("json", 1)
                    .queryParam("tagtype_0", "countries")
                    .queryParam("tag_contains_0", "contains")
                    .queryParam("tag_0", paisTag)
                    .queryParam("page_size", 24)
                    .queryParam("fields", SEARCH_FIELDS)
                    .build().encode().toUriString();

            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "SafeBiteApp/1.0 (contacto@safebite.com)");
            ResponseEntity<Map> response = pedirBusqueda(url, headers);
            Map<String, Object> body = response.getBody();
            List<Map<String, Object>> productos = body == null ? List.of()
                    : (List<Map<String, Object>>) body.getOrDefault("products", List.of());

            List<ProductoSimilar> resultado = new ArrayList<>();
            for (Map<String, Object> p : productos) {
                String nombre = p.get("product_name") == null ? null : String.valueOf(p.get("product_name"));
                String ingredientes = p.get("ingredients_text") == null ? null : String.valueOf(p.get("ingredients_text"));
                if (nombre == null || nombre.isBlank() || ingredientes == null || ingredientes.isBlank()) continue;

                Set<TipoIntolerancia> alergenos = new HashSet<>();
                alergenos.addAll(mapearAlergenos((List<String>) p.getOrDefault("allergens_tags", List.of())));
                alergenos.addAll(mapearAlergenos((List<String>) p.getOrDefault("traces_tags", List.of())));
                alergenos.addAll(alergenoTextAnalyzer.detectar(ingredientes));

                resultado.add(new ProductoSimilar(
                        p.get("code") == null ? null : String.valueOf(p.get("code")), nombre,
                        p.get("brands") == null ? null : String.valueOf(p.get("brands")),
                        nombrePais(paisTag),
                        p.get("image_small_url") == null ? null : String.valueOf(p.get("image_small_url")),
                        ingredientes, alergenos));
            }
            cacheSimilares.put(clave, new EntradaCache(System.currentTimeMillis() + CACHE_MS, resultado));
            return resultado;

        } catch (Exception e) {
            String msg = String.valueOf(e.getMessage());
            log.warn("No se pudo buscar similares en Open Food Facts ({} / {}): {}", termino, paisTag,
                    msg.length() > 160 ? msg.substring(0, 160) : msg);
            fallosRecientes.put(clave, System.currentTimeMillis() + PAUSA_FALLO_MS);
            return List.of();
        }
    }

    /** Una consulta a la vez y con pausa entre consultas; ante un 503/429 espera y reintenta una vez. */
    @SuppressWarnings("rawtypes")
    private ResponseEntity<Map> pedirBusqueda(String url, HttpHeaders headers) {
        synchronized (cerrojoBusqueda) {
            for (int intento = 1; ; intento++) {
                esperarTurno();
                try {
                    return restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), Map.class);
                } catch (org.springframework.web.client.HttpStatusCodeException e) {
                    int code = e.getStatusCode().value();
                    if (intento >= 2 || (code != 503 && code != 429)) throw e;
                    try { Thread.sleep(3000); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); throw e; }
                }
            }
        }
    }

    private void esperarTurno() {
        long espera = ultimaBusquedaMs + SEPARACION_MS - System.currentTimeMillis();
        if (espera > 0) {
            try { Thread.sleep(espera); } catch (InterruptedException ie) { Thread.currentThread().interrupt(); }
        }
        ultimaBusquedaMs = System.currentTimeMillis();
    }

    private String nombrePais(String tag) {
        return switch (tag) {
            case "uruguay" -> "Uruguay";
            case "argentina" -> "Argentina";
            case "brazil" -> "Brasil";
            default -> tag;
        };
    }

    private Set<TipoIntolerancia> mapearAlergenos(List<String> tags) {
        Set<TipoIntolerancia> resultado = new HashSet<>();
        for (String tag : tags) {
            String t = tag.toLowerCase();
            if (t.contains("gluten")) {
                resultado.add(TipoIntolerancia.GLUTEN);
            } else if (t.contains("milk") || t.contains("lactose")) {
                resultado.add(TipoIntolerancia.LACTOSA);
            } else if (t.contains("nuts") || t.contains("peanuts")) {
                resultado.add(TipoIntolerancia.FRUTOS_SECOS);
            } else if (t.contains("crustaceans") || t.contains("molluscs") || t.contains("fish")) {
                resultado.add(TipoIntolerancia.MARISCOS);
            }
        }
        return resultado;
    }
}
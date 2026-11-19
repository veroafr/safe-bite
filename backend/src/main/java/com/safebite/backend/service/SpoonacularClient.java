package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.model.TipoIntolerancia;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Cliente de la API de recetas de Spoonacular (https://spoonacular.com/food-api).
 *
 * Términos de uso que respeta este cliente:
 *  - solo se guardan en la base el id, el título y la URL de la imagen;
 *  - ingredientes, pasos y demás datos se piden en vivo y no se guardan ni se cachean;
 *  - la app muestra el enlace a Spoonacular y a la receta original (atribución).
 *
 * El plan gratuito tiene una cuota diaria de "puntos": cada búsqueda o cada
 * receta abierta consume aproximadamente un punto.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SpoonacularClient {

    private static final String BASE = "https://api.spoonacular.com";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${safebite.spoonacular.api-key:}")
    private String apiKey;

    /** Último estado de la cuota informado por Spoonacular (encabezados X-API-Quota-*). */
    private volatile Double cuotaUsada;
    private volatile Double cuotaRestante;
    private volatile LocalDateTime cuotaFecha;
    private volatile String ultimoError;

    public record Resultado(long id, String titulo, String imagen) {}

    public record Detalle(long id, String titulo, String imagen, Integer minutos, Integer porciones,
                          String resumen, List<String> ingredientes, List<String> pasos,
                          String fuenteUrl, String creditos, String spoonacularUrl) {}

    /**
     * Equivalencias entre las intolerancias de SafeBite (lista ANVISA) y los
     * filtros de Spoonacular. Las que no tienen equivalente (ej. látex) se
     * controlan solo con el analizador de ingredientes de SafeBite.
     */
    private static final Map<String, List<String>> EQUIVALENCIAS = Map.ofEntries(
            Map.entry(TipoIntolerancia.TRIGO, List.of("Gluten", "Wheat")),
            Map.entry(TipoIntolerancia.CENTENO, List.of("Gluten")),
            Map.entry(TipoIntolerancia.CEBADA, List.of("Gluten")),
            Map.entry(TipoIntolerancia.AVENA, List.of("Gluten")),
            Map.entry(TipoIntolerancia.CRUSTACEOS, List.of("Shellfish")),
            Map.entry(TipoIntolerancia.HUEVO, List.of("Egg")),
            Map.entry(TipoIntolerancia.PESCADO, List.of("Seafood")),
            Map.entry(TipoIntolerancia.MANI, List.of("Peanut")),
            Map.entry(TipoIntolerancia.SOJA, List.of("Soy")),
            Map.entry(TipoIntolerancia.LECHE, List.of("Dairy")),
            Map.entry(TipoIntolerancia.ALMENDRA, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.AVELLANA, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.CASTANA_CAJU, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.CASTANA_PARA, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.MACADAMIA, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.NUEZ, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.PECAN, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.PISTACHO, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.PINON, List.of("Tree Nut")),
            Map.entry(TipoIntolerancia.CASTANA, List.of("Tree Nut")));

    public static Set<String> filtrosSpoonacular(Collection<String> codigos) {
        Set<String> r = new LinkedHashSet<>();
        if (codigos != null) for (String c : codigos) r.addAll(EQUIVALENCIAS.getOrDefault(c, List.of()));
        return r;
    }

    /** Códigos de SafeBite que Spoonacular no sabe filtrar. */
    public static Set<String> sinEquivalente(Collection<String> codigos) {
        Set<String> r = new LinkedHashSet<>();
        if (codigos != null) for (String c : codigos) if (!EQUIVALENCIAS.containsKey(c)) r.add(c);
        return r;
    }

    public boolean configurado() {
        return apiKey != null && !apiKey.isBlank();
    }

    public List<Resultado> buscar(String consulta, Collection<String> codigos, int cantidad, int desde) {
        UriComponentsBuilder url = UriComponentsBuilder.fromHttpUrl(BASE + "/recipes/complexSearch")
                .queryParam("number", Math.max(1, Math.min(cantidad, 20)))
                .queryParam("offset", Math.max(0, desde))
                .queryParam("instructionsRequired", true);
        if (consulta != null && !consulta.isBlank()) url.queryParam("query", consulta.trim());
        Set<String> filtros = filtrosSpoonacular(codigos);
        if (!filtros.isEmpty()) url.queryParam("intolerances", String.join(",", filtros));

        JsonNode raiz = pedir(url.encode().build().toUri());
        List<Resultado> lista = new ArrayList<>();
        for (JsonNode r : raiz.path("results")) {
            lista.add(new Resultado(r.path("id").asLong(), r.path("title").asText(""), texto(r, "image")));
        }
        return lista;
    }

    public Detalle detalle(long id) {
        java.net.URI url = UriComponentsBuilder.fromHttpUrl(BASE + "/recipes/" + id + "/information")
                .queryParam("includeNutrition", false).encode().build().toUri();
        JsonNode r = pedir(url);

        List<String> ingredientes = new ArrayList<>();
        for (JsonNode i : r.path("extendedIngredients")) {
            String t = i.path("original").asText("").trim();
            if (!t.isEmpty()) ingredientes.add(t);
        }
        List<String> pasos = new ArrayList<>();
        for (JsonNode bloque : r.path("analyzedInstructions")) {
            for (JsonNode paso : bloque.path("steps")) {
                String t = paso.path("step").asText("").trim();
                if (!t.isEmpty()) pasos.add(t);
            }
        }
        if (pasos.isEmpty()) {
            String html = r.path("instructions").asText("");
            for (String linea : sinHtml(html.replaceAll("(?i)</(li|p)>|<br\\s*/?>", "\n")).split("\n")) {
                if (!linea.isBlank()) pasos.add(linea.trim());
            }
        }
        return new Detalle(
                r.path("id").asLong(id),
                r.path("title").asText(""),
                texto(r, "image"),
                r.hasNonNull("readyInMinutes") ? r.path("readyInMinutes").asInt() : null,
                r.hasNonNull("servings") ? r.path("servings").asInt() : null,
                recortar(sinHtml(r.path("summary").asText("")), 600),
                ingredientes,
                pasos,
                texto(r, "sourceUrl"),
                texto(r, "creditsText"),
                texto(r, "spoonacularSourceUrl"));
    }

    /** Para el panel de administración. */
    public Map<String, Object> estado() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("configurado", configurado());
        m.put("cuotaUsada", cuotaUsada);
        m.put("cuotaRestante", cuotaRestante);
        m.put("actualizado", cuotaFecha);
        m.put("ultimoError", ultimoError);
        return m;
    }

    // ---------- interno ----------

    private JsonNode pedir(java.net.URI url) {
        if (!configurado()) {
            throw new BadRequestException("Falta configurar SPOONACULAR_API_KEY en el servidor.");
        }
        HttpHeaders headers = new HttpHeaders();
        // La clave va en el encabezado para que no quede en los logs con la URL.
        headers.set("x-api-key", apiKey.trim());
        try {
            ResponseEntity<String> resp = restTemplate.exchange(url, HttpMethod.GET, new HttpEntity<>(headers), String.class);
            leerCuota(resp.getHeaders());
            ultimoError = null;
            return objectMapper.readTree(resp.getBody());
        } catch (HttpClientErrorException e) {
            leerCuota(e.getResponseHeaders());
            int status = e.getStatusCode().value();
            String mensaje = switch (status) {
                case 401 -> "Spoonacular rechazó la clave (SPOONACULAR_API_KEY). Revisala en Render.";
                case 402 -> "Se terminó la cuota diaria gratuita de Spoonacular. Se renueva a la medianoche UTC.";
                case 404 -> "Spoonacular no encontró esa receta.";
                case 429 -> "Spoonacular recibió demasiados pedidos seguidos. Probá de nuevo en un minuto.";
                default -> "Spoonacular respondió con error " + status + ".";
            };
            ultimoError = mensaje;
            log.warn("Spoonacular {}: {}", status, e.getResponseBodyAsString());
            throw new BadRequestException(mensaje);
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            ultimoError = "No se pudo conectar con Spoonacular: " + e.getMessage();
            log.warn("Error consultando Spoonacular: {}", e.getMessage());
            throw new BadRequestException("No se pudo conectar con Spoonacular. Probá de nuevo más tarde.");
        }
    }

    private void leerCuota(HttpHeaders h) {
        if (h == null) return;
        Double usada = numero(h.getFirst("X-API-Quota-Used"));
        Double restante = numero(h.getFirst("X-API-Quota-Left"));
        if (usada != null || restante != null) {
            cuotaUsada = usada;
            cuotaRestante = restante;
            cuotaFecha = LocalDateTime.now();
        }
    }

    private static Double numero(String v) {
        try {
            return v == null ? null : Double.parseDouble(v.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private static String texto(JsonNode n, String campo) {
        String t = n.path(campo).asText(null);
        return t == null || t.isBlank() ? null : t.trim();
    }

    static String sinHtml(String html) {
        if (html == null) return "";
        return html.replaceAll("<[^>]+>", "")
                .replace("&amp;", "&").replace("&nbsp;", " ").replace("&quot;", "\"").replace("&#39;", "'")
                .replaceAll("[ \\t]+", " ").trim();
    }

    private static String recortar(String t, int max) {
        if (t == null || t.length() <= max) return t;
        int corte = t.lastIndexOf('.', max);
        return (corte > max / 2 ? t.substring(0, corte + 1) : t.substring(0, max) + "…");
    }
}

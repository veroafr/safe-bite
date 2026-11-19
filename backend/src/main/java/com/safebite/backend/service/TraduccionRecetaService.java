package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.*;

/**
 * Traduce al español las recetas que llegan en inglés (Spoonacular), con
 * Claude y, si no está disponible, con Gemini. La traducción se hace en el
 * momento de mostrar la receta y no se guarda (términos de Spoonacular).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TraduccionRecetaService {

    private final ClaudeClient claude;
    private final VisionAnalysisService gemini;
    private final ObjectMapper objectMapper;

    public record Traduccion(String titulo, String resumen, List<String> ingredientes, List<String> pasos) {}

    public Optional<Traduccion> traducir(SpoonacularClient.Detalle d) {
        Map<String, Object> entrada = new LinkedHashMap<>();
        entrada.put("titulo", d.titulo());
        entrada.put("resumen", d.resumen() == null ? "" : d.resumen());
        entrada.put("ingredientes", d.ingredientes());
        entrada.put("pasos", d.pasos());

        String prompt = """
                Traducí esta receta del inglés al español (neutro, entendible en Uruguay).
                Reglas:
                - Devolvé SOLO un objeto JSON con las claves "titulo", "resumen", "ingredientes" y "pasos".
                - "ingredientes" y "pasos" deben tener exactamente la misma cantidad de elementos y el mismo orden que la entrada.
                - Traducí las unidades (cup = taza, tablespoon/tbsp = cucharada, teaspoon/tsp = cucharadita,
                  ounce/oz = onza, pound/lb = libra). Si hay onzas, libras o grados Fahrenheit, agregá entre
                  paréntesis el equivalente aproximado en gramos o grados Celsius.
                - No agregues ni quites ingredientes ni pasos, no des consejos ni comentarios.
                - En "resumen" escribí como máximo 2 oraciones, sin publicidad ni puntajes.

                Receta:
                """ + json(entrada);

        Optional<String> respuesta = claude.enviar("TRADUCCION_RECETA",
                List.of(Map.of("type", "text", "text", prompt)), 4000);
        if (respuesta.isEmpty()) respuesta = gemini.consultarGeminiTexto(prompt, "TRADUCCION_RECETA");
        if (respuesta.isEmpty()) return Optional.empty();

        try {
            JsonNode r = objectMapper.readTree(limpiar(respuesta.get()));
            List<String> ingredientes = lista(r.path("ingredientes"));
            List<String> pasos = lista(r.path("pasos"));
            if (ingredientes.size() != d.ingredientes().size() || pasos.size() != d.pasos().size()) {
                log.warn("La traducción de la receta {} no respetó la cantidad de elementos", d.id());
                return Optional.empty();
            }
            return Optional.of(new Traduccion(
                    r.path("titulo").asText(d.titulo()),
                    r.path("resumen").asText(""),
                    ingredientes, pasos));
        } catch (Exception e) {
            log.warn("No se pudo leer la traducción de la receta {}: {}", d.id(), e.getMessage());
            return Optional.empty();
        }
    }

    /** Traduce una lista de títulos (resultados de búsqueda del panel admin). */
    public List<String> traducirTitulos(List<String> titulos) {
        if (titulos.isEmpty()) return titulos;
        String prompt = """
                Traducí al español estos títulos de recetas. Devolvé SOLO un JSON con la clave "titulos":
                una lista con la misma cantidad de elementos y en el mismo orden.
                """ + json(Map.of("titulos", titulos));
        Optional<String> respuesta = claude.enviar("TRADUCCION_TITULOS",
                List.of(Map.of("type", "text", "text", prompt)), 2000);
        if (respuesta.isEmpty()) respuesta = gemini.consultarGeminiTexto(prompt, "TRADUCCION_TITULOS");
        try {
            if (respuesta.isPresent()) {
                List<String> r = lista(objectMapper.readTree(limpiar(respuesta.get())).path("titulos"));
                if (r.size() == titulos.size()) return r;
            }
        } catch (Exception e) {
            log.warn("No se pudieron traducir los títulos: {}", e.getMessage());
        }
        return titulos;
    }

    /** Spoonacular busca en inglés: traduce lo que el admin escribe en español. */
    public String traducirConsulta(String consulta) {
        if (consulta == null || consulta.isBlank()) return consulta;
        String prompt = """
                Traducí al inglés este término de búsqueda de recetas. Devolvé SOLO un JSON {"en": "..."}.
                Término:\s""" + consulta.trim();
        Optional<String> respuesta = claude.enviar("TRADUCCION_BUSQUEDA",
                List.of(Map.of("type", "text", "text", prompt)), 1000);
        if (respuesta.isEmpty()) respuesta = gemini.consultarGeminiTexto(prompt, "TRADUCCION_BUSQUEDA");
        try {
            if (respuesta.isPresent()) {
                String en = objectMapper.readTree(limpiar(respuesta.get())).path("en").asText("").trim();
                if (!en.isEmpty()) return en;
            }
        } catch (Exception e) {
            log.warn("No se pudo traducir la búsqueda: {}", e.getMessage());
        }
        return consulta;
    }

    private String json(Object o) {
        try {
            return objectMapper.writeValueAsString(o);
        } catch (Exception e) {
            return String.valueOf(o);
        }
    }

    private static List<String> lista(JsonNode n) {
        List<String> r = new ArrayList<>();
        if (n != null && n.isArray()) for (JsonNode e : n) r.add(e.asText("").trim());
        return r;
    }

    /** Quita los ``` que a veces rodean al JSON. */
    private static String limpiar(String t) {
        String s = t.trim();
        if (s.startsWith("```")) {
            s = s.replaceFirst("^```[a-zA-Z]*\\s*", "");
            int fin = s.lastIndexOf("```");
            if (fin >= 0) s = s.substring(0, fin);
        }
        int inicio = s.indexOf('{');
        int fin = s.lastIndexOf('}');
        return inicio >= 0 && fin > inicio ? s.substring(inicio, fin + 1) : s;
    }
}

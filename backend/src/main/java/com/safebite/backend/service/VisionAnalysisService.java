package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.safebite.backend.model.TipoIntolerancia;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Usa la API de vision de Google Gemini para leer las fotos de un producto
 * (frente, tabla de composicion, tabla nutricional) y devolver datos
 * estructurados: nombre, marca, ingredientes y alergenos.
 *
 * Es un asistente para completar el formulario mas rapido - el usuario o
 * el admin siempre revisa y confirma antes de guardar, no se guarda solo.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class VisionAnalysisService {

    private static final String GEMINI_URL =
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${safebite.gemini.api-key:}")
    private String apiKey;

    public record AnalisisFotos(
            String nombreSugerido,
            String marcaSugerida,
            String categoriaSugerida,
            List<String> ingredientes,
            Set<TipoIntolerancia> alergenos,
            boolean pudoLeer,
            String observacion
    ) {}

    public AnalisisFotos analizar(String fotoFrontalBase64, String fotoComposicionBase64, String fotoNutricionalBase64) {
        if (apiKey == null || apiKey.isBlank()) {
            log.warn("GEMINI_API_KEY no configurada, no se puede analizar la foto");
            return new AnalisisFotos(null, null, null, List.of(), Set.of(), false,
                    "El analisis con IA no esta configurado en el servidor todavia.");
        }

        List<Map<String, Object>> partes = new ArrayList<>();
        partes.add(Map.of(
                "text", """
                        Sos un asistente que ayuda a cargar productos alimenticios en una app \
                        para personas con alergias/intolerancias alimentarias en Uruguay.
                        Te paso una o mas fotos de un producto (puede venir el frente del envase, \
                        la tabla de ingredientes, y/o la tabla nutricional). Analizalas y devolveme \
                        SOLO un JSON (sin texto adicional, sin markdown) con esta forma exacta:
                        {
                          "nombreSugerido": "nombre del producto o null si no se lee",
                          "marcaSugerida": "marca o null",
                          "categoriaSugerida": "una categoria corta como Panificados, Lacteos, Snacks, Bebidas, Conservas, Condimentos, Congelados, u otra que corresponda, o null",
                          "ingredientes": ["ingrediente 1", "ingrediente 2"],
                          "alergenos": ["GLUTEN", "LACTOSA", "FRUTOS_SECOS", "MARISCOS"],
                          "pudoLeer": true,
                          "observacion": "aviso breve si la foto esta borrosa, incompleta, o si tenes baja confianza en algo"
                        }
                        Los unicos valores validos para "alergenos" son GLUTEN, LACTOSA, FRUTOS_SECOS, MARISCOS \
                        (incluí solo los que el ingrediente realmente contenga o pueda contener segun la etiqueta). \
                        Si ninguna foto se puede leer con confianza, poné "pudoLeer": false y explicá por que en "observacion".
                        """
        ));

        agregarImagenSiExiste(partes, fotoFrontalBase64);
        agregarImagenSiExiste(partes, fotoComposicionBase64);
        agregarImagenSiExiste(partes, fotoNutricionalBase64);

        if (partes.size() == 1) {
            // Solo el texto, ninguna imagen real
            return new AnalisisFotos(null, null, null, List.of(), Set.of(), false, "No se recibio ninguna foto para analizar.");
        }

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("contents", List.of(Map.of("parts", partes)));
        body.put("generationConfig", Map.of("responseMimeType", "application/json"));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        String url = UriComponentsBuilder.fromHttpUrl(GEMINI_URL)
                .queryParam("key", apiKey)
                .toUriString();

        try {
            ResponseEntity<String> response = restTemplate.exchange(
                    url, org.springframework.http.HttpMethod.POST,
                    new HttpEntity<>(body, headers), String.class);

            JsonNode raiz = objectMapper.readTree(response.getBody());
            String textoRespuesta = raiz.path("candidates").path(0)
                    .path("content").path("parts").path(0).path("text").asText("");

            String json = extraerJson(textoRespuesta);
            JsonNode datos = objectMapper.readTree(json);

            List<String> ingredientes = new ArrayList<>();
            datos.path("ingredientes").forEach(n -> ingredientes.add(n.asText()));

            Set<TipoIntolerancia> alergenos = new HashSet<>();
            datos.path("alergenos").forEach(n -> {
                try {
                    alergenos.add(TipoIntolerancia.valueOf(n.asText()));
                } catch (IllegalArgumentException ignored) {
                    // la IA devolvio algo que no matchea el enum, se ignora
                }
            });

            return new AnalisisFotos(
                    textoONull(datos, "nombreSugerido"),
                    textoONull(datos, "marcaSugerida"),
                    textoONull(datos, "categoriaSugerida"),
                    ingredientes,
                    alergenos,
                    datos.path("pudoLeer").asBoolean(true),
                    textoONull(datos, "observacion")
            );

        } catch (Exception e) {
            log.warn("Error analizando fotos con IA: {}", e.getMessage());
            return new AnalisisFotos(null, null, null, List.of(), Set.of(), false,
                    "No se pudo completar el analisis en este momento. Intenta cargar los datos a mano.");
        }
    }

    private void agregarImagenSiExiste(List<Map<String, Object>> partes, String base64) {
        if (base64 == null || base64.isBlank()) return;
        partes.add(Map.of(
                "inline_data", Map.of(
                        "mime_type", "image/jpeg",
                        "data", base64
                )
        ));
    }

    private String extraerJson(String texto) {
        int inicio = texto.indexOf('{');
        int fin = texto.lastIndexOf('}');
        if (inicio == -1 || fin == -1 || fin < inicio) return "{}";
        return texto.substring(inicio, fin + 1);
    }

    private String textoONull(JsonNode nodo, String campo) {
        JsonNode valor = nodo.path(campo);
        if (valor.isMissingNode() || valor.isNull()) return null;
        String texto = valor.asText();
        return texto.isBlank() ? null : texto;
    }
}
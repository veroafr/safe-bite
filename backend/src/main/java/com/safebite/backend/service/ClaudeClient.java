package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.HttpServerErrorException;
import org.springframework.web.client.RestTemplate;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/** Cliente minimo de la API de mensajes de Claude (Anthropic). */
@Slf4j
@Service
@RequiredArgsConstructor
public class ClaudeClient {

    private static final String URL = "https://api.anthropic.com/v1/messages";

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final IaGastoService gasto;

    @Value("${safebite.claude.api-key:}")
    private String apiKey;

    @Value("${safebite.claude.model:claude-haiku-5-5}")
    private String model;

    /** USD por millon de tokens (por defecto, precios de Haiku 5.5). Cambialos si cambias de modelo. */
    @Value("${safebite.claude.price-in-per-mtok:0.10}")
    private double precioEntrada;

    @Value("${safebite.claude.price-out-per-mtok:0.50}")
    private double precioSalida;

    /** Hay clave cargada y todavia queda presupuesto. */
    public boolean disponible() {
        return apiKey != null && !apiKey.isBlank() && gasto.hayPresupuesto();
    }

    /**
     * Envia un mensaje de usuario con los bloques de contenido dados (texto
     * y/o imagenes) y devuelve el texto de la respuesta. Vacio si falla.
     */
    public Optional<String> enviar(String operacion, List<Map<String, Object>> contenido, int maxTokens) {
        if (!disponible()) return Optional.empty();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("max_tokens", maxTokens);
        body.put("messages", List.of(Map.of("role", "user", "content", contenido)));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey);
        headers.set("anthropic-version", "2023-06-01");

        for (int intento = 1; intento <= 3; intento++) {
            try {
                ResponseEntity<String> resp = restTemplate.exchange(
                        URL, HttpMethod.POST, new HttpEntity<>(body, headers), String.class);
                JsonNode raiz = objectMapper.readTree(resp.getBody());

                int in = raiz.path("usage").path("input_tokens").asInt(0);
                int out = raiz.path("usage").path("output_tokens").asInt(0);
                double costo = in * precioEntrada / 1_000_000.0 + out * precioSalida / 1_000_000.0;
                gasto.registrar("CLAUDE", operacion, in, out, costo);

                String texto = raiz.path("content").path(0).path("text").asText("");
                return texto.isBlank() ? Optional.empty() : Optional.of(texto);

            } catch (HttpServerErrorException | HttpClientErrorException.TooManyRequests e) {
                // 5xx / 529 (sobrecarga) / 429: temporal, se reintenta
                log.warn("Claude fallo (intento {}/3): {}", intento, e.getStatusCode());
                if (intento < 3) pausar(1500L * intento);
            } catch (HttpClientErrorException e) {
                // 400 (ej. saldo insuficiente), 401 (clave invalida), 404 (modelo): no tiene sentido reintentar
                log.warn("Claude rechazo la consulta: {} {}", e.getStatusCode(), e.getResponseBodyAsString());
                return Optional.empty();
            } catch (Exception e) {
                log.warn("Error consultando a Claude: {}", e.getMessage());
                return Optional.empty();
            }
        }
        return Optional.empty();
    }

    private void pausar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }
}

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
import org.springframework.web.client.HttpStatusCodeException;
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
    private final IaEstadoService estado;

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
        headers.set("x-api-key", apiKey.trim());
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
                if (texto.isBlank()) {
                    estado.error("CLAUDE", "Claude respondio sin texto (" + operacion + ")");
                    return Optional.empty();
                }
                estado.exito("CLAUDE", operacion + " con " + model);
                return Optional.of(texto);

            } catch (HttpServerErrorException | HttpClientErrorException.TooManyRequests e) {
                // 5xx / 529 (sobrecarga) / 429: temporal, se reintenta
                log.warn("Claude fallo (intento {}/3): {}", intento, e.getStatusCode());
                estado.error("CLAUDE", IaEstadoService.explicar("Claude", e.getStatusCode().value(), e.getResponseBodyAsString())
                        + " - " + e.getResponseBodyAsString());
                if (intento < 3) pausar(1500L * intento);
            } catch (HttpClientErrorException e) {
                // 400 (ej. saldo insuficiente), 401 (clave invalida), 404 (modelo): no tiene sentido reintentar
                log.warn("Claude rechazo la consulta: {} {}", e.getStatusCode(), e.getResponseBodyAsString());
                estado.error("CLAUDE", IaEstadoService.explicar("Claude", e.getStatusCode().value(), e.getResponseBodyAsString())
                        + " - " + e.getResponseBodyAsString());
                return Optional.empty();
            } catch (Exception e) {
                log.warn("Error consultando a Claude: {}", e.getMessage());
                estado.error("CLAUDE", "Claude: no se pudo conectar - " + e.getMessage());
                return Optional.empty();
            }
        }
        return Optional.empty();
    }

    public boolean claveConfigurada() {
        return apiKey != null && !apiKey.isBlank();
    }

    public String modelo() {
        return model;
    }

    /** Ultimos 4 caracteres de la clave, para reconocer cual esta cargada sin mostrarla. */
    public String finClave() {
        if (!claveConfigurada()) return null;
        String k = apiKey.trim();
        return "..." + k.substring(Math.max(0, k.length() - 4));
    }

    /**
     * Consulta minima de prueba (unos pocos tokens) para saber si la clave,
     * el modelo y el saldo funcionan. No respeta el presupuesto a proposito:
     * cuesta una fraccion de centavo y es la forma de diagnosticar.
     */
    public Map<String, Object> probar() {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("claveConfigurada", claveConfigurada());
        r.put("finClave", finClave());
        r.put("modelo", model);
        r.put("hayPresupuesto", gasto.hayPresupuesto());
        if (!claveConfigurada()) {
            r.put("ok", false);
            r.put("mensaje", "Falta la variable ANTHROPIC_API_KEY en Render (Environment). Sin ella nunca se usa Claude.");
            return r;
        }
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", model);
        body.put("max_tokens", 5);
        body.put("messages", List.of(Map.of("role", "user", "content", "Responde solo: OK")));
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("x-api-key", apiKey.trim());
        headers.set("anthropic-version", "2023-06-01");
        try {
            ResponseEntity<String> resp = restTemplate.exchange(
                    URL, HttpMethod.POST, new HttpEntity<>(body, headers), String.class);
            JsonNode raiz = objectMapper.readTree(resp.getBody());
            int in = raiz.path("usage").path("input_tokens").asInt(0);
            int out = raiz.path("usage").path("output_tokens").asInt(0);
            gasto.registrar("CLAUDE", "DIAGNOSTICO", in, out,
                    in * precioEntrada / 1_000_000.0 + out * precioSalida / 1_000_000.0);
            estado.exito("CLAUDE", "Diagnostico correcto con " + model);
            r.put("ok", true);
            r.put("mensaje", gasto.hayPresupuesto()
                    ? "Claude responde correctamente."
                    : "Claude responde, pero se alcanzo el presupuesto configurado: la app no lo usa hasta subir IA_PRESUPUESTO_USD.");
        } catch (HttpStatusCodeException e) {
            String explicacion = IaEstadoService.explicar("Claude", e.getStatusCode().value(), e.getResponseBodyAsString());
            estado.error("CLAUDE", explicacion + " - " + e.getResponseBodyAsString());
            r.put("ok", false);
            r.put("mensaje", explicacion);
            r.put("respuestaApi", e.getResponseBodyAsString());
        } catch (Exception e) {
            estado.error("CLAUDE", "Claude: no se pudo conectar - " + e.getMessage());
            r.put("ok", false);
            r.put("mensaje", "No se pudo conectar con la API de Claude: " + e.getMessage());
        }
        return r;
    }

    private void pausar(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException ie) {
            Thread.currentThread().interrupt();
        }
    }
}

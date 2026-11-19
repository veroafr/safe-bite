package com.safebite.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.model.Traduccion;
import com.safebite.backend.repository.TraduccionRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.*;

/**
 * Traduce contenido (recetas, noticias, reseñas, mensajes...) al español o al
 * portugués con IA (Claude y, de respaldo, Gemini). Cada traducción se guarda
 * en la base: un mismo texto se traduce una sola vez por idioma.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TraduccionContenidoService {

    public static final Set<String> IDIOMAS = Set.of("es", "pt");
    private static final int MAX_TEXTOS = 60;
    private static final int MAX_LARGO = 6000;
    private static final int POR_CONSULTA = 25;

    private final TraduccionRepository repository;
    private final ClaudeClient claude;
    private final VisionAnalysisService gemini;
    private final ObjectMapper objectMapper;

    public Map<String, String> traducir(String idioma, List<String> textos) {
        if (idioma == null || !IDIOMAS.contains(idioma)) throw new BadRequestException("Idioma no soportado");
        if (textos == null || textos.isEmpty()) return Map.of();
        if (textos.size() > MAX_TEXTOS) throw new BadRequestException("Demasiados textos en un solo pedido");

        List<String> validos = textos.stream()
                .filter(Objects::nonNull)
                .filter(t -> !t.isBlank() && t.length() <= MAX_LARGO)
                .distinct().toList();

        Map<String, String> claves = new LinkedHashMap<>();
        for (String t : validos) claves.put(clave(idioma, t), t);

        Map<String, String> resultado = new LinkedHashMap<>();
        for (Traduccion tr : repository.findByClaveIn(claves.keySet())) resultado.put(tr.getOriginal(), tr.getTraducido());

        List<String> faltan = validos.stream().filter(t -> !resultado.containsKey(t)).toList();
        for (int i = 0; i < faltan.size(); i += POR_CONSULTA) {
            List<String> lote = faltan.subList(i, Math.min(faltan.size(), i + POR_CONSULTA));
            Map<String, String> nuevas = consultarIa(idioma, lote);
            for (Map.Entry<String, String> e : nuevas.entrySet()) {
                resultado.put(e.getKey(), e.getValue());
                try {
                    repository.save(Traduccion.builder()
                            .clave(clave(idioma, e.getKey())).idioma(idioma)
                            .original(e.getKey()).traducido(e.getValue()).build());
                } catch (Exception ex) {
                    // Otro pedido la guardó al mismo tiempo: no pasa nada.
                }
            }
        }
        return resultado;
    }

    /** Traduce un solo texto (o lo devuelve igual si no se pudo). */
    public String traducirUno(String idioma, String texto) {
        if (texto == null || texto.isBlank() || !IDIOMAS.contains(idioma)) return texto;
        return traducir(idioma, List.of(texto)).getOrDefault(texto, texto);
    }

    private Map<String, String> consultarIa(String idioma, List<String> textos) {
        String destino = "pt".equals(idioma) ? "portugués de Brasil" : "español (neutro, entendible en Uruguay)";
        String prompt = """
                Traducí cada texto de la lista al %s. Son textos de una app sobre restricciones alimentarias
                (recetas, noticias, reseñas, mensajes). Reglas:
                - Si un texto ya está en ese idioma, devolvelo igual.
                - No traduzcas nombres propios, marcas, nombres de locales, direcciones ni e-mails.
                - Mantené números, unidades, emojis, saltos de línea y el formato.
                - No agregues explicaciones.
                Devolvé SOLO un objeto JSON {"traducciones": [...]} con la misma cantidad de elementos y en el mismo orden.

                Lista:
                """.formatted(destino) + json(Map.of("textos", textos));

        Optional<String> respuesta = claude.enviar("TRADUCCION_CONTENIDO", List.of(Map.of("type", "text", "text", prompt)), 4000);
        if (respuesta.isEmpty()) respuesta = gemini.consultarGeminiTexto(prompt, "TRADUCCION_CONTENIDO");
        if (respuesta.isEmpty()) return Map.of();
        try {
            JsonNode lista = objectMapper.readTree(limpiar(respuesta.get())).path("traducciones");
            if (!lista.isArray() || lista.size() != textos.size()) {
                log.warn("La traducción devolvió {} elementos para {} textos", lista.size(), textos.size());
                return Map.of();
            }
            Map<String, String> r = new LinkedHashMap<>();
            for (int i = 0; i < textos.size(); i++) {
                String t = lista.get(i).asText("").trim();
                if (!t.isEmpty()) r.put(textos.get(i), t);
            }
            return r;
        } catch (Exception e) {
            log.warn("No se pudo leer la traducción: {}", e.getMessage());
            return Map.of();
        }
    }

    private String json(Object o) {
        try {
            return objectMapper.writeValueAsString(o);
        } catch (Exception e) {
            return String.valueOf(o);
        }
    }

    private static String limpiar(String t) {
        String s = t.trim();
        int inicio = s.indexOf('{');
        int fin = s.lastIndexOf('}');
        return inicio >= 0 && fin > inicio ? s.substring(inicio, fin + 1) : s;
    }

    private static String clave(String idioma, String texto) {
        try {
            byte[] h = MessageDigest.getInstance("SHA-256").digest((idioma + "|" + texto).getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : h) sb.append(String.format("%02x", b));
            return sb.toString();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}

package com.safebite.backend.service;

import java.util.Base64;

/**
 * Prepara una foto en base64 para enviarla a la IA: quita el prefijo
 * "data:image/...;base64," si viene, y detecta el formato real mirando los
 * primeros bytes. Antes se declaraba siempre "image/jpeg", y Claude rechaza
 * la consulta (HTTP 400) cuando la foto es PNG o WebP.
 */
public record ImagenBase64(String datos, String mimeType) {

    /** Formatos que aceptan Claude y Gemini. */
    public boolean admitida() {
        return mimeType != null;
    }

    public static ImagenBase64 de(String base64) {
        if (base64 == null) return new ImagenBase64(null, null);
        String datos = base64.trim();
        int coma = datos.indexOf(',');
        if (datos.startsWith("data:") && coma > 0) {
            datos = datos.substring(coma + 1);
        }
        datos = datos.replaceAll("\\s", "");
        return new ImagenBase64(datos, detectar(datos));
    }

    private static String detectar(String datos) {
        byte[] b;
        try {
            String inicio = datos.substring(0, Math.min(datos.length(), 32));
            inicio = inicio.substring(0, inicio.length() - inicio.length() % 4);
            b = Base64.getDecoder().decode(inicio);
        } catch (Exception e) {
            return null;
        }
        if (b.length >= 3 && (b[0] & 0xFF) == 0xFF && (b[1] & 0xFF) == 0xD8 && (b[2] & 0xFF) == 0xFF) {
            return "image/jpeg";
        }
        if (b.length >= 4 && (b[0] & 0xFF) == 0x89 && b[1] == 'P' && b[2] == 'N' && b[3] == 'G') {
            return "image/png";
        }
        if (b.length >= 3 && b[0] == 'G' && b[1] == 'I' && b[2] == 'F') {
            return "image/gif";
        }
        if (b.length >= 12 && b[0] == 'R' && b[1] == 'I' && b[2] == 'F' && b[3] == 'F'
                && b[8] == 'W' && b[9] == 'E' && b[10] == 'B' && b[11] == 'P') {
            return "image/webp";
        }
        // HEIC/HEIF (fotos de iPhone) u otro formato: no lo aceptan las APIs.
        return null;
    }
}

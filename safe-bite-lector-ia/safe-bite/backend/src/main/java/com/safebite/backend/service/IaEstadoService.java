package com.safebite.backend.service;

import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Guarda en memoria el ultimo error y el ultimo exito de cada proveedor de IA
 * (Claude y Gemini), para que el administrador vea por que no se esta usando
 * uno de ellos sin tener que leer los logs de Render.
 */
@Service
public class IaEstadoService {

    private record Evento(LocalDateTime fecha, String detalle) {}

    private final Map<String, Evento> ultimoError = new ConcurrentHashMap<>();
    private final Map<String, Evento> ultimoExito = new ConcurrentHashMap<>();

    public void error(String proveedor, String detalle) {
        ultimoError.put(proveedor, new Evento(LocalDateTime.now(), recortar(detalle)));
    }

    public void exito(String proveedor, String detalle) {
        ultimoExito.put(proveedor, new Evento(LocalDateTime.now(), recortar(detalle)));
    }

    /** Texto corto del ultimo error, o null si no hubo. */
    public String ultimoErrorTexto(String proveedor) {
        Evento e = ultimoError.get(proveedor);
        return e == null ? null : e.detalle();
    }

    public Map<String, Object> resumen(String proveedor) {
        Map<String, Object> r = new LinkedHashMap<>();
        Evento err = ultimoError.get(proveedor);
        Evento ok = ultimoExito.get(proveedor);
        r.put("ultimoError", err == null ? null : err.detalle());
        r.put("ultimoErrorFecha", err == null ? null : err.fecha().toString());
        r.put("ultimoExito", ok == null ? null : ok.detalle());
        r.put("ultimoExitoFecha", ok == null ? null : ok.fecha().toString());
        return r;
    }

    /**
     * Traduce un codigo HTTP de error de la API a una explicacion en
     * castellano, para mostrarla en el panel.
     */
    public static String explicar(String proveedor, int status, String cuerpo) {
        String c = cuerpo == null ? "" : cuerpo.toLowerCase();
        String motivo;
        if (status == 401 || status == 403) {
            motivo = "la clave de API es invalida o no tiene permiso";
        } else if (status == 404) {
            motivo = "el modelo configurado no existe o no esta disponible para esta clave";
        } else if (status == 429) {
            motivo = c.contains("limit: 0") || c.contains("free_tier")
                    ? "la cuenta no tiene cuota gratuita para este modelo"
                    : "se supero el limite de uso (cuota o demasiadas consultas)";
        } else if (status == 400 && (c.contains("credit") || c.contains("billing") || c.contains("balance"))) {
            motivo = "la cuenta no tiene saldo o creditos disponibles";
        } else if (status == 400 && c.contains("image")) {
            motivo = "la API rechazo la imagen (formato o tamano no admitido)";
        } else if (status == 400) {
            motivo = "la API rechazo la consulta";
        } else if (status >= 500) {
            motivo = "el servicio del proveedor esta caido o sobrecargado";
        } else {
            motivo = "error inesperado";
        }
        return proveedor + ": " + motivo + " (HTTP " + status + ")";
    }

    private static String recortar(String s) {
        if (s == null) return null;
        return s.length() > 600 ? s.substring(0, 600) + "..." : s;
    }
}

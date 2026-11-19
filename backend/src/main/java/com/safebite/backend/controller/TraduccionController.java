package com.safebite.backend.controller;

import com.safebite.backend.service.TraduccionContenidoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Traducción de contenido para la app en español / portugués (requiere sesión). */
@RestController
@RequestMapping("/api/traducciones")
@RequiredArgsConstructor
public class TraduccionController {

    private final TraduccionContenidoService service;

    /** Body: {"idioma": "pt", "textos": ["...", "..."]} → {"traducciones": {"original": "traducido"}} */
    @PostMapping
    public ResponseEntity<Map<String, Object>> traducir(@RequestBody Map<String, Object> body) {
        Object idioma = body.get("idioma");
        List<String> textos = new ArrayList<>();
        if (body.get("textos") instanceof List<?> l) for (Object o : l) if (o != null) textos.add(o.toString());
        return ResponseEntity.ok(Map.of("traducciones", service.traducir(idioma == null ? null : idioma.toString(), textos)));
    }
}

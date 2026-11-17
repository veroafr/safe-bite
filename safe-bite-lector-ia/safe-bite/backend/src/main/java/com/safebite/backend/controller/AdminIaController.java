package com.safebite.backend.controller;

import com.safebite.backend.service.ClaudeClient;
import com.safebite.backend.service.IaEstadoService;
import com.safebite.backend.service.IaGastoService;
import com.safebite.backend.service.VisionAnalysisService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/** Panel admin: cuanto se lleva gastado en IA (estimado) y cuanto queda del presupuesto. */
@RestController
@RequestMapping("/api/admin/ia")
@RequiredArgsConstructor
public class AdminIaController {

    private final IaGastoService gasto;
    private final IaEstadoService estado;
    private final ClaudeClient claude;
    private final VisionAnalysisService vision;

    @GetMapping("/uso")
    public ResponseEntity<Map<String, Object>> uso() {
        Map<String, Object> r = new LinkedHashMap<>(gasto.resumen());
        r.put("claude", estado.resumen("CLAUDE"));
        r.put("gemini", estado.resumen("GEMINI"));
        return ResponseEntity.ok(r);
    }

    /**
     * Hace una consulta minima a Claude y a Gemini y explica que falla:
     * clave faltante o invalida, modelo inexistente, sin saldo o sin cuota.
     */
    @GetMapping("/diagnostico")
    public ResponseEntity<Map<String, Object>> diagnostico() {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("claude", claude.probar());
        r.put("gemini", vision.probarGemini());
        r.put("uso", gasto.resumen());
        return ResponseEntity.ok(r);
    }
}

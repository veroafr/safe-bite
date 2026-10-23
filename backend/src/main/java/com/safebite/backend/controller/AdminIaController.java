package com.safebite.backend.controller;

import com.safebite.backend.service.IaGastoService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/** Panel admin: cuanto se lleva gastado en IA (estimado) y cuanto queda del presupuesto. */
@RestController
@RequestMapping("/api/admin/ia")
@RequiredArgsConstructor
public class AdminIaController {

    private final IaGastoService gasto;

    @GetMapping("/uso")
    public ResponseEntity<Map<String, Object>> uso() {
        return ResponseEntity.ok(gasto.resumen());
    }
}

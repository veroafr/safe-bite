package com.safebite.backend.controller;

import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecetaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/recetas")
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;

    @GetMapping
    public ResponseEntity<List<RecetaResponse>> listar(
            @RequestParam(required = false) Boolean esTip,
            @RequestParam(required = false) String filtrarPorIntolerancia,
            @RequestParam(required = false) List<String> intolerancias,
            @RequestParam(required = false, defaultValue = "false") boolean usarMisIntolerancias,
            @AuthenticationPrincipal Usuario usuario) {
        List<String> filtro = new ArrayList<>();
        if (filtrarPorIntolerancia != null && !filtrarPorIntolerancia.isBlank()) filtro.add(filtrarPorIntolerancia);
        if (intolerancias != null) filtro.addAll(intolerancias);
        if (usarMisIntolerancias && usuario != null) filtro.addAll(usuario.getIntolerancias());
        return ResponseEntity.ok(recetaService.listar(esTip, filtro));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RecetaResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(recetaService.obtener(id));
    }
}

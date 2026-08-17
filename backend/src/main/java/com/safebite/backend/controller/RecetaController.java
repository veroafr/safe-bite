package com.safebite.backend.controller;

import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecetaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recetas")
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;

    @GetMapping
    public ResponseEntity<List<RecetaResponse>> listar(
            @RequestParam(required = false) Boolean esTip,
            @RequestParam(required = false) TipoIntolerancia filtrarPorIntolerancia,
            @RequestParam(required = false, defaultValue = "false") boolean usarMisIntolerancias,
            @AuthenticationPrincipal Usuario usuario) {
        var intoleranciasUsuario = (usarMisIntolerancias && usuario != null) ? usuario.getIntolerancias() : null;
        return ResponseEntity.ok(recetaService.listar(esTip, filtrarPorIntolerancia, intoleranciasUsuario));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RecetaResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(recetaService.obtener(id));
    }
}

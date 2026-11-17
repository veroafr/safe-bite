package com.safebite.backend.controller;

import com.safebite.backend.dto.request.RecetaRequest;
import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecetaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/recetas")
@RequiredArgsConstructor
public class AdminRecetaController {

    private final RecetaService recetaService;

    @PostMapping
    public ResponseEntity<RecetaResponse> crear(@AuthenticationPrincipal Usuario admin, @Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(recetaService.crear(request, admin));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RecetaResponse> editar(@PathVariable Long id, @Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.ok(recetaService.editar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        recetaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

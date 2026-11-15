package com.safebite.backend.controller;

import com.safebite.backend.dto.request.IntoleranciaRequest;
import com.safebite.backend.dto.response.IntoleranciaResponse;
import com.safebite.backend.service.IntoleranciaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/intolerancias")
@RequiredArgsConstructor
public class AdminIntoleranciaController {

    private final IntoleranciaService intoleranciaService;

    @GetMapping
    public ResponseEntity<List<IntoleranciaResponse>> listarTodas() {
        return ResponseEntity.ok(intoleranciaService.listarTodas());
    }

    @PostMapping
    public ResponseEntity<IntoleranciaResponse> crear(@Valid @RequestBody IntoleranciaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(intoleranciaService.crear(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<IntoleranciaResponse> editar(@PathVariable Long id, @Valid @RequestBody IntoleranciaRequest request) {
        return ResponseEntity.ok(intoleranciaService.editar(id, request));
    }

    @PatchMapping("/{id}/estado")
    public ResponseEntity<IntoleranciaResponse> cambiarEstado(@PathVariable Long id, @RequestBody Map<String, Boolean> body) {
        return ResponseEntity.ok(intoleranciaService.cambiarEstado(id, Boolean.TRUE.equals(body.get("activa"))));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        intoleranciaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

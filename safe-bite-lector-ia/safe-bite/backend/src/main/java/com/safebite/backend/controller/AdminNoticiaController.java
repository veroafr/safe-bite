package com.safebite.backend.controller;

import com.safebite.backend.dto.request.NoticiaRequest;
import com.safebite.backend.dto.response.NoticiaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.NoticiaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/noticias")
@RequiredArgsConstructor
public class AdminNoticiaController {

    private final NoticiaService noticiaService;

    @PostMapping
    public ResponseEntity<NoticiaResponse> crear(@AuthenticationPrincipal Usuario admin, @Valid @RequestBody NoticiaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(noticiaService.crear(request, admin));
    }

    @PutMapping("/{id}")
    public ResponseEntity<NoticiaResponse> editar(@PathVariable Long id, @Valid @RequestBody NoticiaRequest request) {
        return ResponseEntity.ok(noticiaService.editar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        noticiaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

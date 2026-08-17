package com.safebite.backend.controller;

import com.safebite.backend.dto.request.AlertaRequest;
import com.safebite.backend.dto.response.AlertaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.AlertaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/alertas")
@RequiredArgsConstructor
public class AlertaController {

    private final AlertaService alertaService;

    @PostMapping
    public ResponseEntity<AlertaResponse> crear(@AuthenticationPrincipal Usuario usuario,
                                                 @Valid @RequestBody AlertaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(alertaService.crear(request, usuario));
    }

    @GetMapping("/me")
    public ResponseEntity<List<AlertaResponse>> misAlertas(@AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(alertaService.listarDeUsuario(usuario.getId()));
    }
}

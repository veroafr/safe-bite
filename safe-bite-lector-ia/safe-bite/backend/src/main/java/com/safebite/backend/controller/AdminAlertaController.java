package com.safebite.backend.controller;

import com.safebite.backend.dto.request.RevisarAlertaRequest;
import com.safebite.backend.dto.response.AlertaResponse;
import com.safebite.backend.model.EstadoAlerta;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.AlertaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/alertas")
@RequiredArgsConstructor
public class AdminAlertaController {

    private final AlertaService alertaService;

    @GetMapping
    public ResponseEntity<List<AlertaResponse>> listar(@RequestParam(required = false) EstadoAlerta estado) {
        return ResponseEntity.ok(alertaService.listarPorEstado(estado));
    }

    @PutMapping("/{id}/revisar")
    public ResponseEntity<AlertaResponse> revisar(@PathVariable Long id,
                                                    @AuthenticationPrincipal Usuario admin,
                                                    @Valid @RequestBody RevisarAlertaRequest request) {
        return ResponseEntity.ok(alertaService.revisar(id, request, admin));
    }
}

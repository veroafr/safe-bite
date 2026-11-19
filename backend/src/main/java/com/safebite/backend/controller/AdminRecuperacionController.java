package com.safebite.backend.controller;

import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecuperacionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/** Pedidos de recuperación de contraseña que atiende el administrador. */
@RestController
@RequestMapping("/api/admin/recuperaciones")
@RequiredArgsConstructor
public class AdminRecuperacionController {

    private final RecuperacionService recuperacionService;

    /** estado: PENDIENTE (por defecto), RESUELTA, DESCARTADA o TODAS. */
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> listar(@RequestParam(defaultValue = "PENDIENTE") String estado) {
        return ResponseEntity.ok(recuperacionService.listar(estado));
    }

    /** Body: {"password": "Nueva#123", "nota": "le avisé por WhatsApp"} */
    @PutMapping("/{id}/resolver")
    public ResponseEntity<Map<String, Object>> resolver(@PathVariable Long id, @AuthenticationPrincipal Usuario admin,
                                                        @RequestBody Map<String, String> body) {
        return ResponseEntity.ok(recuperacionService.resolver(id, body.get("password"), body.get("nota"), admin));
    }

    @PutMapping("/{id}/descartar")
    public ResponseEntity<Map<String, Object>> descartar(@PathVariable Long id, @AuthenticationPrincipal Usuario admin,
                                                         @RequestBody(required = false) Map<String, String> body) {
        return ResponseEntity.ok(recuperacionService.descartar(id, body == null ? null : body.get("nota"), admin));
    }
}

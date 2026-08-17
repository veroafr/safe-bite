package com.safebite.backend.controller;

import com.safebite.backend.dto.request.ActualizarPerfilRequest;
import com.safebite.backend.dto.request.CambiarPasswordRequest;
import com.safebite.backend.dto.request.PreferenciasRequest;
import com.safebite.backend.dto.response.UsuarioResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.UsuarioService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/usuarios")
@RequiredArgsConstructor
public class UsuarioController {

    private final UsuarioService usuarioService;

    @GetMapping("/me")
    public ResponseEntity<UsuarioResponse> perfil(@AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(UsuarioResponse.desde(usuario));
    }

    @PutMapping("/me")
    public ResponseEntity<UsuarioResponse> actualizarPerfil(@AuthenticationPrincipal Usuario usuario,
                                                              @RequestBody ActualizarPerfilRequest request) {
        return ResponseEntity.ok(usuarioService.actualizarPerfil(usuario, request));
    }

    @PutMapping("/me/password")
    public ResponseEntity<Void> cambiarPassword(@AuthenticationPrincipal Usuario usuario,
                                                 @Valid @RequestBody CambiarPasswordRequest request) {
        usuarioService.cambiarPassword(usuario, request);
        return ResponseEntity.noContent().build();
    }

    @PutMapping("/me/preferencias")
    public ResponseEntity<UsuarioResponse> actualizarPreferencias(@AuthenticationPrincipal Usuario usuario,
                                                                    @RequestBody PreferenciasRequest request) {
        return ResponseEntity.ok(usuarioService.actualizarPreferencias(usuario, request));
    }
}

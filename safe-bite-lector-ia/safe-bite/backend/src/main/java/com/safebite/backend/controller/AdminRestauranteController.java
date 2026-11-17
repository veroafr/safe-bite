package com.safebite.backend.controller;

import com.safebite.backend.dto.request.RestauranteRequest;
import com.safebite.backend.dto.response.RestauranteResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RestauranteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/restaurantes")
@RequiredArgsConstructor
public class AdminRestauranteController {

    private final RestauranteService restauranteService;

    @PostMapping
    public ResponseEntity<RestauranteResponse> crear(@AuthenticationPrincipal Usuario admin,
                                                       @Valid @RequestBody RestauranteRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(restauranteService.crear(request, admin));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RestauranteResponse> editar(@PathVariable Long id, @Valid @RequestBody RestauranteRequest request) {
        return ResponseEntity.ok(restauranteService.editar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        restauranteService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

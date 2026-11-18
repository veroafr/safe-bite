package com.safebite.backend.controller;

import com.safebite.backend.dto.request.ComentarioRequest;
import com.safebite.backend.dto.request.EvaluacionRequest;
import com.safebite.backend.dto.response.ComentarioResponse;
import com.safebite.backend.dto.response.EvaluacionResponse;
import com.safebite.backend.dto.response.RestauranteResponse;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RestauranteService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/restaurantes")
@RequiredArgsConstructor
public class RestauranteController {

    private final RestauranteService restauranteService;

    @GetMapping
    public ResponseEntity<List<RestauranteResponse>> buscar(
            @RequestParam(required = false) String nombre,
            @RequestParam(required = false) String tipoCocina,
            @RequestParam(required = false) String intolerancia,
            @RequestParam(required = false) List<String> intolerancias) {
        List<String> filtro = new java.util.ArrayList<>();
        if (intolerancia != null && !intolerancia.isBlank()) filtro.add(intolerancia);
        if (intolerancias != null) filtro.addAll(intolerancias);
        return ResponseEntity.ok(restauranteService.buscar(nombre, tipoCocina, filtro));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RestauranteResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(restauranteService.obtener(id));
    }

    @GetMapping("/{id}/comentarios")
    public ResponseEntity<List<ComentarioResponse>> listarComentarios(@PathVariable Long id) {
        return ResponseEntity.ok(restauranteService.listarComentarios(id));
    }

    @PostMapping("/{id}/comentarios")
    public ResponseEntity<ComentarioResponse> comentar(@PathVariable Long id,
                                                         @AuthenticationPrincipal Usuario usuario,
                                                         @Valid @RequestBody ComentarioRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(restauranteService.comentar(id, usuario, request));
    }

    @GetMapping("/{id}/evaluaciones")
    public ResponseEntity<List<EvaluacionResponse>> listarEvaluaciones(@PathVariable Long id) {
        return ResponseEntity.ok(restauranteService.listarEvaluaciones(id));
    }

    /** La reseña propia del usuario (para ver si está pendiente, aprobada o rechazada). */
    @GetMapping("/{id}/mi-evaluacion")
    public ResponseEntity<EvaluacionResponse> miEvaluacion(@PathVariable Long id,
                                                         @org.springframework.security.core.annotation.AuthenticationPrincipal com.safebite.backend.model.Usuario usuario) {
        if (usuario == null) return ResponseEntity.noContent().build();
        return restauranteService.miEvaluacion(id, usuario)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.noContent().build());
    }

    @PostMapping("/{id}/evaluaciones")
    public ResponseEntity<EvaluacionResponse> evaluar(@PathVariable Long id,
                                                        @AuthenticationPrincipal Usuario usuario,
                                                        @Valid @RequestBody EvaluacionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(restauranteService.evaluar(id, usuario, request));
    }
}

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
            @RequestParam(required = false) TipoIntolerancia intolerancia) {
        return ResponseEntity.ok(restauranteService.buscar(nombre, tipoCocina, intolerancia));
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

    @PostMapping("/{id}/evaluaciones")
    public ResponseEntity<EvaluacionResponse> evaluar(@PathVariable Long id,
                                                        @AuthenticationPrincipal Usuario usuario,
                                                        @Valid @RequestBody EvaluacionRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(restauranteService.evaluar(id, usuario, request));
    }
}

package com.safebite.backend.controller;

import com.safebite.backend.dto.response.IntoleranciaResponse;
import com.safebite.backend.service.IntoleranciaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Lista publica (se usa en el registro, antes de iniciar sesion). */
@RestController
@RequestMapping("/api/intolerancias")
@RequiredArgsConstructor
public class IntoleranciaController {

    private final IntoleranciaService intoleranciaService;

    @GetMapping
    public ResponseEntity<List<IntoleranciaResponse>> listar() {
        return ResponseEntity.ok(intoleranciaService.listarActivas());
    }
}

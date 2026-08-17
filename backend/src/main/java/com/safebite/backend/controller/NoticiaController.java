package com.safebite.backend.controller;

import com.safebite.backend.dto.response.NoticiaResponse;
import com.safebite.backend.service.NoticiaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/noticias")
@RequiredArgsConstructor
public class NoticiaController {

    private final NoticiaService noticiaService;

    @GetMapping
    public ResponseEntity<List<NoticiaResponse>> listar(@RequestParam(required = false) String etiqueta) {
        return ResponseEntity.ok(noticiaService.listar(etiqueta));
    }

    @GetMapping("/{id}")
    public ResponseEntity<NoticiaResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(noticiaService.obtener(id));
    }
}

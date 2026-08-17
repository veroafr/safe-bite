package com.safebite.backend.controller;

import com.safebite.backend.dto.request.OcrRequest;
import com.safebite.backend.dto.response.AnalisisIngredientesResponse;
import com.safebite.backend.dto.response.EscaneoResponse;
import com.safebite.backend.dto.response.ProductoResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;

    @GetMapping("/buscar")
    public ResponseEntity<List<ProductoResponse>> buscar(@RequestParam String nombre) {
        return ResponseEntity.ok(productoService.buscarPorNombre(nombre));
    }

    @GetMapping("/ean/{codigo}")
    public ResponseEntity<EscaneoResponse> escanearEan(@PathVariable String codigo,
                                                         @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.escanearPorEan(codigo, usuario));
    }

    @PostMapping("/ocr")
    public ResponseEntity<EscaneoResponse> escanearOcr(@Valid @RequestBody OcrRequest request,
                                                         @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.escanearPorOcr(request.getTextoDetectado(), usuario));
    }

    @PostMapping("/analizar-ingredientes")
    public ResponseEntity<AnalisisIngredientesResponse> analizarIngredientes(@Valid @RequestBody OcrRequest request,
                                                                               @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.analizarIngredientes(request.getTextoDetectado(), usuario));
    }
}
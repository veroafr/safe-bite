package com.safebite.backend.controller;

import com.safebite.backend.dto.request.FotoProductoRequest;
import com.safebite.backend.dto.request.ProductoRequest;
import com.safebite.backend.dto.response.ProductoResponse;
import com.safebite.backend.service.ProductoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/productos")
@RequiredArgsConstructor
public class AdminProductoController {

    private final ProductoService productoService;

    @GetMapping
    public ResponseEntity<List<ProductoResponse>> listar() {
        return ResponseEntity.ok(productoService.listarTodos());
    }

    @GetMapping("/pendientes")
    public ResponseEntity<List<ProductoResponse>> listarPendientes() {
        return ResponseEntity.ok(productoService.listarPendientes());
    }

    @PostMapping
    public ResponseEntity<ProductoResponse> crear(@Valid @RequestBody ProductoRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(productoService.crear(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ProductoResponse> editar(@PathVariable Long id, @Valid @RequestBody ProductoRequest request) {
        return ResponseEntity.ok(productoService.editar(id, request));
    }

    /**
     * Reemplazar o eliminar UNA foto puntual de un producto pendiente,
     * sin tener que abrir el formulario completo de edicion.
     */
    @PutMapping("/{id}/foto")
    public ResponseEntity<ProductoResponse> actualizarFoto(@PathVariable Long id,
                                                             @Valid @RequestBody FotoProductoRequest request) {
        return ResponseEntity.ok(productoService.actualizarFoto(id, request.getTipo(), request.getBase64()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        productoService.eliminar(id);
        return ResponseEntity.noContent().build();
    }
}

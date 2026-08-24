package com.safebite.backend.controller;

import com.safebite.backend.dto.request.AnalizarFotosRequest;
import com.safebite.backend.dto.request.AportarProductoRequest;
import com.safebite.backend.dto.request.OcrRequest;
import com.safebite.backend.dto.response.AnalisisFotosResponse;
import com.safebite.backend.dto.response.AnalisisIngredientesResponse;
import com.safebite.backend.dto.response.EscaneoResponse;
import com.safebite.backend.dto.response.ProductoResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.ProductoService;
import com.safebite.backend.service.VisionAnalysisService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/productos")
@RequiredArgsConstructor
public class ProductoController {

    private final ProductoService productoService;
    private final VisionAnalysisService visionAnalysisService;

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

    @PostMapping("/aportar")
    public ResponseEntity<ProductoResponse> aportar(@Valid @RequestBody AportarProductoRequest request,
                                                      @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.status(HttpStatus.CREATED).body(productoService.aportar(request, usuario));
    }

    @PutMapping("/{id}/completar")
    public ResponseEntity<ProductoResponse> completarDatos(@PathVariable Long id,
                                                             @Valid @RequestBody AportarProductoRequest request,
                                                             @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.completarDatos(id, request, usuario));
    }

    /**
     * IA de vision: lee las fotos (frente/composicion/nutricional) que el
     * usuario o el admin sacaron y sugiere nombre, marca, categoria,
     * ingredientes y alergenos para pre-completar el formulario. Siempre
     * requiere revision antes de guardar - esto no crea ni edita nada solo.
     * Se usa tanto desde el formulario de carga como desde "Escanear paquete".
     */
    @PostMapping("/analizar-fotos")
    public ResponseEntity<AnalisisFotosResponse> analizarFotos(@Valid @RequestBody AnalizarFotosRequest request) {
        var resultado = visionAnalysisService.analizar(
                request.getFotoFrontalBase64(), request.getFotoComposicionBase64(), request.getFotoNutricionalBase64());

        return ResponseEntity.ok(AnalisisFotosResponse.builder()
                .nombreSugerido(resultado.nombreSugerido())
                .marcaSugerida(resultado.marcaSugerida())
                .categoriaSugerida(resultado.categoriaSugerida())
                .ingredientes(resultado.ingredientes())
                .alergenos(resultado.alergenos())
                .pudoLeer(resultado.pudoLeer())
                .observacion(resultado.observacion())
                .build());
    }
}

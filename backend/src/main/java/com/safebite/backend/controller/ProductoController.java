package com.safebite.backend.controller;

import com.safebite.backend.dto.request.AnalizarFotosRequest;
import com.safebite.backend.dto.request.AportarProductoRequest;
import com.safebite.backend.dto.request.OcrRequest;
import com.safebite.backend.dto.request.RecomendarRequest;
import com.safebite.backend.dto.response.RecomendacionesResponse;
import com.safebite.backend.service.RecomendacionService;
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
    private final RecomendacionService recomendacionService;
    private final com.safebite.backend.service.OpenFoodFactsService openFoodFacts;

    /** Foto de referencia para una recomendación (Open Food Facts). Devuelve {"url": "..."} o {"url": null}. */
    @GetMapping("/imagen")
    public ResponseEntity<java.util.Map<String, String>> imagen(@RequestParam String q) {
        String texto = q.length() > 120 ? q.substring(0, 120) : q;
        java.util.Map<String, String> r = new java.util.HashMap<>();
        r.put("url", openFoodFacts.buscarImagen(texto).orElse(null));
        return ResponseEntity.ok(r);
    }

    @GetMapping("/buscar")
    public ResponseEntity<List<ProductoResponse>> buscar(@RequestParam(required = false, defaultValue = "") String nombre,
                                                         @RequestParam(required = false) List<String> excluirIntolerancias) {
        return ResponseEntity.ok(productoService.buscarPorNombre(nombre, excluirIntolerancias));
    }

    @GetMapping("/ean/{codigo}")
    public ResponseEntity<EscaneoResponse> escanearEan(@PathVariable String codigo,
                                                         @RequestParam(required = false) List<String> intolerancias,
                                                         @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.escanearPorEan(codigo, usuario, intolerancias));
    }

    @PostMapping("/ocr")
    public ResponseEntity<EscaneoResponse> escanearOcr(@Valid @RequestBody OcrRequest request,
                                                         @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.escanearPorOcr(request.getTextoDetectado(), usuario, request.getIntolerancias()));
    }

    @PostMapping("/analizar-ingredientes")
    public ResponseEntity<AnalisisIngredientesResponse> analizarIngredientes(@Valid @RequestBody OcrRequest request,
                                                                               @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(productoService.analizarIngredientes(request.getTextoDetectado(), usuario, request.getIntolerancias()));
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
                .tipoProducto(resultado.tipoProducto())
                .terminoBusquedaEs(resultado.terminoBusquedaEs())
                .terminoBusquedaPt(resultado.terminoBusquedaPt())
                .ingredientes(resultado.ingredientes())
                .alergenos(resultado.alergenos())
                .pudoLeer(resultado.pudoLeer())
                .observacion(resultado.observacion())
                .proveedor(resultado.proveedor())
                .codigoBarras(resultado.codigoBarras())
                .build());
    }

    /**
     * "Esto no, pero esto si": alternativas aptas para el usuario logueado,
     * a partir de un producto leido con "Escanear paquete". Busca en la base
     * propia y en Open Food Facts (Uruguay, Argentina, Brasil) y la IA elige
     * y explica. El veredicto apto/no apto lo deciden reglas, no la IA.
     */
    @PostMapping("/recomendar")
    public ResponseEntity<RecomendacionesResponse> recomendar(@RequestBody RecomendarRequest request,
                                                                @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(recomendacionService.recomendar(request, usuario));
    }
}

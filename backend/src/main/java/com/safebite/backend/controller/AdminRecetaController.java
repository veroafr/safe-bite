package com.safebite.backend.controller;

import com.safebite.backend.dto.request.RecetaRequest;
import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecetaService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/recetas")
@RequiredArgsConstructor
public class AdminRecetaController {

    private final RecetaService recetaService;

    @PostMapping
    public ResponseEntity<RecetaResponse> crear(@AuthenticationPrincipal Usuario admin, @Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(recetaService.crear(request, admin));
    }

    @PutMapping("/{id}")
    public ResponseEntity<RecetaResponse> editar(@PathVariable Long id, @Valid @RequestBody RecetaRequest request) {
        return ResponseEntity.ok(recetaService.editar(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        recetaService.eliminar(id);
        return ResponseEntity.noContent().build();
    }

    // ---- Moderación ----

    /** Recetas por estado: PENDIENTE (por defecto), APROBADA o RECHAZADA. */
    @GetMapping
    public ResponseEntity<java.util.List<RecetaResponse>> listar(@RequestParam(required = false) String estado) {
        return ResponseEntity.ok(recetaService.listarPorEstado(estado));
    }

    /** Body: {"aprobar": true|false, "motivo": "opcional"} */
    @PutMapping("/{id}/moderar")
    public ResponseEntity<RecetaResponse> moderar(@PathVariable Long id, @RequestBody java.util.Map<String, Object> body) {
        Object motivo = body.get("motivo");
        return ResponseEntity.ok(recetaService.moderar(id, Boolean.TRUE.equals(body.get("aprobar")),
                motivo == null ? null : motivo.toString()));
    }

    // ---- Spoonacular ----

    @GetMapping("/spoonacular/buscar")
    public ResponseEntity<java.util.Map<String, Object>> buscarSpoonacular(
            @RequestParam(required = false) String consulta,
            @RequestParam(required = false) java.util.List<String> intolerancias,
            @RequestParam(defaultValue = "0") int pagina) {
        return ResponseEntity.ok(recetaService.buscarEnSpoonacular(consulta, intolerancias, pagina));
    }

    @GetMapping("/spoonacular/estado")
    public ResponseEntity<java.util.Map<String, Object>> estadoSpoonacular() {
        return ResponseEntity.ok(recetaService.estadoSpoonacular());
    }

    @GetMapping("/spoonacular/{externoId}")
    public ResponseEntity<RecetaResponse> vistaPrevia(@PathVariable long externoId,
                                                      @RequestParam(required = false) java.util.List<String> intolerancias) {
        return ResponseEntity.ok(recetaService.vistaPreviaSpoonacular(externoId, intolerancias));
    }

    /** Body: {"externoId": 123, "titulo": "en español", "libreDe": ["TRIGO", ...]} */
    @PostMapping("/spoonacular")
    public ResponseEntity<RecetaResponse> importar(@AuthenticationPrincipal Usuario admin,
                                                   @RequestBody java.util.Map<String, Object> body) {
        Object id = body.get("externoId");
        if (!(id instanceof Number n)) throw new com.safebite.backend.exception.BadRequestException("Falta externoId");
        Object titulo = body.get("titulo");
        java.util.List<String> libreDe = new java.util.ArrayList<>();
        if (body.get("libreDe") instanceof java.util.List<?> l) for (Object o : l) libreDe.add(String.valueOf(o));
        return ResponseEntity.status(HttpStatus.CREATED).body(
                recetaService.importarDeSpoonacular(n.longValue(), titulo == null ? null : titulo.toString(), libreDe, admin));
    }
}

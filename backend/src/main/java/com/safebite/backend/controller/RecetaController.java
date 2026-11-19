package com.safebite.backend.controller;

import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.service.RecetaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/recetas")
@RequiredArgsConstructor
public class RecetaController {

    private final RecetaService recetaService;

    @GetMapping
    public ResponseEntity<List<RecetaResponse>> listar(
            @RequestParam(required = false) Boolean esTip,
            @RequestParam(required = false) String filtrarPorIntolerancia,
            @RequestParam(required = false) List<String> intolerancias,
            @RequestParam(required = false, defaultValue = "false") boolean usarMisIntolerancias,
            @AuthenticationPrincipal Usuario usuario) {
        List<String> filtro = new ArrayList<>();
        if (filtrarPorIntolerancia != null && !filtrarPorIntolerancia.isBlank()) filtro.add(filtrarPorIntolerancia);
        if (intolerancias != null) filtro.addAll(intolerancias);
        if (usarMisIntolerancias && usuario != null) filtro.addAll(usuario.getIntolerancias());
        return ResponseEntity.ok(recetaService.listar(esTip, filtro));
    }

    @GetMapping("/{id}")
    public ResponseEntity<RecetaResponse> obtener(@PathVariable Long id, @AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(recetaService.obtener(id, usuario));
    }

    /** Recetas de Spoonacular en vivo, filtradas por intolerancias. */
    @GetMapping("/externas")
    public ResponseEntity<List<RecetaResponse>> externas(
            @RequestParam(required = false) String consulta,
            @RequestParam(required = false) List<String> intolerancias,
            @RequestParam(defaultValue = "0") int pagina) {
        return ResponseEntity.ok(recetaService.externas(consulta, intolerancias, pagina));
    }

    @GetMapping("/externas/{externoId}")
    public ResponseEntity<RecetaResponse> externa(@PathVariable long externoId,
                                                 @RequestParam(required = false) List<String> intolerancias) {
        return ResponseEntity.ok(recetaService.externa(externoId, intolerancias));
    }

    /** Una persona envía su receta: queda pendiente hasta que el admin la apruebe. */
    @PostMapping("/propuestas")
    public ResponseEntity<RecetaResponse> proponer(@AuthenticationPrincipal Usuario usuario,
                                                   @RequestBody com.safebite.backend.dto.request.RecetaRequest request) {
        return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED).body(recetaService.proponer(request, usuario));
    }

    @PutMapping("/propuestas/{id}")
    public ResponseEntity<RecetaResponse> editarPropuesta(@PathVariable Long id, @AuthenticationPrincipal Usuario usuario,
                                                         @RequestBody com.safebite.backend.dto.request.RecetaRequest request) {
        return ResponseEntity.ok(recetaService.editarPropuesta(id, request, usuario));
    }

    /** Recetas que envió la persona, con su estado (pendiente / aprobada / rechazada). */
    @GetMapping("/mis-propuestas")
    public ResponseEntity<List<RecetaResponse>> misPropuestas(@AuthenticationPrincipal Usuario usuario) {
        return ResponseEntity.ok(recetaService.misPropuestas(usuario));
    }
}

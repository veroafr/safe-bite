package com.safebite.backend.controller;

import com.safebite.backend.dto.response.ReporteResponse;
import com.safebite.backend.service.ReporteService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/reportes")
@RequiredArgsConstructor
public class AdminReporteController {

    private final ReporteService reporteService;

    @GetMapping("/estadisticas")
    public ResponseEntity<ReporteResponse> estadisticas() {
        return ResponseEntity.ok(reporteService.obtenerEstadisticas());
    }

    @GetMapping("/exportar-pdf")
    public ResponseEntity<byte[]> exportarPdf() {
        byte[] pdf = reporteService.exportarPdf();
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=reporte-safebite.pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(pdf);
    }
}

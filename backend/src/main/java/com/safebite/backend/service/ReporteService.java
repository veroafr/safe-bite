package com.safebite.backend.service;

import com.safebite.backend.dto.response.ReporteResponse;
import com.safebite.backend.model.EstadoAlerta;
import com.safebite.backend.model.Rol;
import com.safebite.backend.repository.*;
import com.lowagie.text.Document;
import com.lowagie.text.Element;
import com.lowagie.text.Font;
import com.lowagie.text.FontFactory;
import com.lowagie.text.PageSize;
import com.lowagie.text.Paragraph;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfWriter;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.time.format.DateTimeFormatter;

@Service
@RequiredArgsConstructor
public class ReporteService {

    private final UsuarioRepository usuarioRepository;
    private final RestauranteRepository restauranteRepository;
    private final RecetaRepository recetaRepository;
    private final NoticiaRepository noticiaRepository;
    private final ProductoRepository productoRepository;
    private final AlertaRepository alertaRepository;

    public ReporteResponse obtenerEstadisticas() {
        return ReporteResponse.builder()
                .totalUsuarios(usuarioRepository.countByRol(Rol.USUARIO))
                .totalRestaurantes(restauranteRepository.count())
                .totalRecetas(recetaRepository.count())
                .totalNoticias(noticiaRepository.count())
                .totalProductos(productoRepository.count())
                .alertasPendientes(alertaRepository.countByEstado(EstadoAlerta.PENDIENTE))
                .alertasAceptadas(alertaRepository.countByEstado(EstadoAlerta.ACEPTADA))
                .alertasDenegadas(alertaRepository.countByEstado(EstadoAlerta.DENEGADA))
                .build();
    }

    public byte[] exportarPdf() {
        ReporteResponse r = obtenerEstadisticas();
        try {
            Document document = new Document(PageSize.A4);
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            PdfWriter.getInstance(document, out);
            document.open();

            Font tituloFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18);
            Font subFont = FontFactory.getFont(FontFactory.HELVETICA, 10);

            Paragraph titulo = new Paragraph("Safe-Bite — Reporte de Estadisticas", tituloFont);
            titulo.setAlignment(Element.ALIGN_CENTER);
            document.add(titulo);

            Paragraph fecha = new Paragraph(
                    "Generado el " + java.time.LocalDateTime.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")),
                    subFont);
            fecha.setAlignment(Element.ALIGN_CENTER);
            fecha.setSpacingAfter(20);
            document.add(fecha);

            PdfPTable tabla = new PdfPTable(2);
            tabla.setWidthPercentage(100);
            agregarFila(tabla, "Usuarios registrados", String.valueOf(r.getTotalUsuarios()));
            agregarFila(tabla, "Restaurantes activos", String.valueOf(r.getTotalRestaurantes()));
            agregarFila(tabla, "Recetas publicadas", String.valueOf(r.getTotalRecetas()));
            agregarFila(tabla, "Noticias publicadas", String.valueOf(r.getTotalNoticias()));
            agregarFila(tabla, "Productos catalogados", String.valueOf(r.getTotalProductos()));
            agregarFila(tabla, "Alertas pendientes", String.valueOf(r.getAlertasPendientes()));
            agregarFila(tabla, "Alertas aceptadas", String.valueOf(r.getAlertasAceptadas()));
            agregarFila(tabla, "Alertas denegadas", String.valueOf(r.getAlertasDenegadas()));
            document.add(tabla);

            document.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Error generando el PDF de reportes: " + e.getMessage(), e);
        }
    }

    private void agregarFila(PdfPTable tabla, String etiqueta, String valor) {
        tabla.addCell(etiqueta);
        tabla.addCell(valor);
    }
}

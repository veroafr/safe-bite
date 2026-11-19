package com.safebite.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReporteResponse {
    private LocalDateTime generado;

    private long totalUsuarios;
    private long usuariosActivos;
    private long totalRestaurantes;
    private long totalRecetas;
    private long totalNoticias;
    private long totalProductos;
    private long totalResenas;
    private long alertasPendientes;
    private long alertasAceptadas;
    private long alertasDenegadas;
    private long productosPendientes;
    private long recetasPendientes;
    private long resenasPendientes;
    private long recuperacionesPendientes;

    /** Variables para graficar (y exportar al PDF). */
    @Builder.Default
    private List<Serie> series = new ArrayList<>();

    /** tipo: "columnas" (evolución en el tiempo) o "barras" (comparación entre categorías). */
    public record Serie(String clave, String titulo, String descripcion, String tipo, String unidad, List<Dato> datos) {}

    public record Dato(String etiqueta, double valor) {}
}

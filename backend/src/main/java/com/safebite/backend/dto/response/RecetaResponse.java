package com.safebite.backend.dto.response;

import com.safebite.backend.model.Receta;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class RecetaResponse {
    private Long id;
    private String titulo;
    private String descripcion;
    private Integer tiempoPreparacionMinutos;
    private String dificultad;
    private String imagenUrl;
    private boolean esTip;
    private Set<String> etiquetas;
    private Set<String> libreDe;
    private List<String> ingredientes;
    private List<String> pasos;
    private LocalDateTime fechaPublicacion;

    private String origen;
    private String estado;
    private String motivoRechazo;
    private String autorNombre;
    private Long externoId;
    private String tituloOriginal;
    /** Fuente de la receta (Spoonacular): nombre, enlace a la original y créditos. */
    private String fuenteNombre;
    private String fuenteUrl;
    private String creditos;
    private Integer porciones;
    /** Intolerancias que el analizador de SafeBite encontró en los ingredientes. */
    private java.util.Set<String> detectados;
    /** detectados que contradicen lo declarado en libreDe (aviso para el admin). */
    private java.util.Set<String> conflictos;
    /** true si el contenido se tradujo automáticamente al español. */
    private Boolean traducida;
    /** Mensaje para mostrar cuando no se pudo cargar el contenido en vivo. */
    private String aviso;

    public static RecetaResponse desde(Receta r) {
        return RecetaResponse.builder()
                .id(r.getId())
                .titulo(r.getTitulo())
                .descripcion(r.getDescripcion())
                .tiempoPreparacionMinutos(r.getTiempoPreparacionMinutos())
                .dificultad(r.getDificultad())
                .imagenUrl(r.getImagenDatos() != null ? r.getImagenDatos() : r.getImagenUrl())
                .esTip(r.isEsTip())
                .etiquetas(r.getEtiquetas())
                .libreDe(r.getLibreDe())
                .ingredientes(r.getIngredientes())
                .pasos(r.getPasos())
                .fechaPublicacion(r.getFechaPublicacion())
                .origen(r.origenEfectivo())
                .estado(r.estadoEfectivo())
                .motivoRechazo(r.getMotivoRechazo())
                .autorNombre(r.getPublicadoPor() != null ? r.getPublicadoPor().getNombre() : null)
                .externoId(r.getExternoId())
                .tituloOriginal(r.getTituloOriginal())
                .fuenteNombre(r.esDeSpoonacular() ? "spoonacular" : null)
                .build();
    }
}

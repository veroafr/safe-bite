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
    private List<String> ingredientes;
    private List<String> pasos;
    private LocalDateTime fechaPublicacion;

    public static RecetaResponse desde(Receta r) {
        return RecetaResponse.builder()
                .id(r.getId())
                .titulo(r.getTitulo())
                .descripcion(r.getDescripcion())
                .tiempoPreparacionMinutos(r.getTiempoPreparacionMinutos())
                .dificultad(r.getDificultad())
                .imagenUrl(r.getImagenUrl())
                .esTip(r.isEsTip())
                .etiquetas(r.getEtiquetas())
                .ingredientes(r.getIngredientes())
                .pasos(r.getPasos())
                .fechaPublicacion(r.getFechaPublicacion())
                .build();
    }
}

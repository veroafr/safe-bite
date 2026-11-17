package com.safebite.backend.dto.response;

import com.safebite.backend.model.Noticia;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NoticiaResponse {
    private Long id;
    private String titulo;
    private String resumen;
    private String contenido;
    private String imagenUrl;
    private Set<String> etiquetas;
    private Set<String> intolerancias;
    private LocalDateTime fechaPublicacion;

    public static NoticiaResponse desde(Noticia n) {
        return NoticiaResponse.builder()
                .id(n.getId())
                .titulo(n.getTitulo())
                .resumen(n.getResumen())
                .contenido(n.getContenido())
                .imagenUrl(n.getImagenUrl())
                .etiquetas(n.getEtiquetas())
                .intolerancias(n.getIntolerancias())
                .fechaPublicacion(n.getFechaPublicacion())
                .build();
    }
}

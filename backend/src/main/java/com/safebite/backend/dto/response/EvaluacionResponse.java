package com.safebite.backend.dto.response;

import com.safebite.backend.model.Evaluacion;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EvaluacionResponse {
    private Long id;
    private Long restauranteId;
    private String usuarioNombre;
    private Integer puntuacion;
    private String comentario;
    private LocalDateTime fecha;

    public static EvaluacionResponse desde(Evaluacion e) {
        return EvaluacionResponse.builder()
                .id(e.getId())
                .restauranteId(e.getRestaurante().getId())
                .usuarioNombre(e.getUsuario().getNombre())
                .puntuacion(e.getPuntuacion())
                .comentario(e.getComentario())
                .fecha(e.getFecha())
                .build();
    }
}

package com.safebite.backend.dto.response;

import com.safebite.backend.model.Comentario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ComentarioResponse {
    private Long id;
    private Long restauranteId;
    private String usuarioNombre;
    private String texto;
    private LocalDateTime fecha;

    public static ComentarioResponse desde(Comentario c) {
        return ComentarioResponse.builder()
                .id(c.getId())
                .restauranteId(c.getRestaurante().getId())
                .usuarioNombre(c.getUsuario().getNombre())
                .texto(c.getTexto())
                .fecha(c.getFecha())
                .build();
    }
}

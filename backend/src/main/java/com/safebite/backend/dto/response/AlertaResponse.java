package com.safebite.backend.dto.response;

import com.safebite.backend.model.Alerta;
import com.safebite.backend.model.EstadoAlerta;
import com.safebite.backend.model.TipoAlerta;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AlertaResponse {
    private Long id;
    private String usuarioNombre;
    private TipoAlerta tipo;
    private Long restauranteId;
    private String restauranteNombre;
    private Long productoId;
    private String productoNombre;
    private String descripcion;
    private EstadoAlerta estado;
    private LocalDateTime fecha;
    private LocalDateTime fechaRevision;

    public static AlertaResponse desde(Alerta a) {
        return AlertaResponse.builder()
                .id(a.getId())
                .usuarioNombre(a.getUsuario() != null ? a.getUsuario().getNombre() : null)
                .tipo(a.getTipo())
                .restauranteId(a.getRestaurante() != null ? a.getRestaurante().getId() : null)
                .restauranteNombre(a.getRestaurante() != null ? a.getRestaurante().getNombre() : null)
                .productoId(a.getProducto() != null ? a.getProducto().getId() : null)
                .productoNombre(a.getProducto() != null ? a.getProducto().getNombre() : null)
                .descripcion(a.getDescripcion())
                .estado(a.getEstado())
                .fecha(a.getFecha())
                .fechaRevision(a.getFechaRevision())
                .build();
    }
}

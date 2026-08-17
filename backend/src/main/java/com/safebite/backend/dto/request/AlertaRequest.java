package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoAlerta;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class AlertaRequest {
    @NotNull
    private TipoAlerta tipo;
    private Long restauranteId;
    private Long productoId;
    @NotBlank
    private String descripcion;
}

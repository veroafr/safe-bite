package com.safebite.backend.dto.request;

import com.safebite.backend.model.EstadoAlerta;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class RevisarAlertaRequest {
    @NotNull
    private EstadoAlerta estado;
}

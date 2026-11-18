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
    @NotBlank(message = "Describí el problema")
    @jakarta.validation.constraints.Size(min = 15, max = 1000, message = "La descripción debe tener entre 15 y 1000 caracteres")
    private String descripcion;

    /** Obligatorio para reportes de restaurantes (lo valida el servicio). */
    @jakarta.validation.constraints.Size(max = 30)
    private String telefonoContacto;

    /** Fotos opcionales en base64 / data URL (máximo 3). */
    private java.util.List<String> pruebas;
}

package com.safebite.backend.dto.request;

import com.safebite.backend.config.Validaciones;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class CambiarPasswordRequest {
    @NotBlank
    private String passwordActual;

    @NotBlank
    @Pattern(regexp = Validaciones.PASSWORD, message = Validaciones.PASSWORD_MENSAJE)
    private String passwordNueva;
}

package com.safebite.backend.dto.request;

import com.safebite.backend.config.Validaciones;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class RecuperarPasswordRequest {
    @NotBlank(message = "El email es obligatorio")
    @Email(message = Validaciones.EMAIL_MENSAJE)
    private String email;
}

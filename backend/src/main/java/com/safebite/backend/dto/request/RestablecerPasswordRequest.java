package com.safebite.backend.dto.request;

import com.safebite.backend.config.Validaciones;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

/** Segundo paso de "Olvidaste tu contraseña": codigo recibido por email + nueva contraseña. */
@Data
public class RestablecerPasswordRequest {
    @NotBlank(message = "El email es obligatorio")
    @Email(message = Validaciones.EMAIL_MENSAJE)
    private String email;

    @NotBlank(message = "Ingresá el código que te enviamos")
    @Pattern(regexp = "^\\d{6}$", message = "El código tiene 6 dígitos")
    private String codigo;

    @NotBlank(message = "La contraseña es obligatoria")
    @Pattern(regexp = Validaciones.PASSWORD, message = Validaciones.PASSWORD_MENSAJE)
    private String passwordNueva;
}

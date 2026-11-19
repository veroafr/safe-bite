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

    /** Teléfono / WhatsApp para que el equipo le avise la contraseña nueva (opcional). */
    @jakarta.validation.constraints.Size(max = 40)
    private String telefono;

    @jakarta.validation.constraints.Size(max = 500)
    private String mensaje;
}

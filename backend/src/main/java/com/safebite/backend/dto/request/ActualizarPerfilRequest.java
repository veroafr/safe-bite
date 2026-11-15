package com.safebite.backend.dto.request;

import com.safebite.backend.config.Validaciones;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

@Data
public class ActualizarPerfilRequest {
    private String nombre;
    @Pattern(regexp = Validaciones.EMAIL, message = Validaciones.EMAIL_MENSAJE)
    private String email;
    private String ciudad;
    private String pais;
    private String fotoPerfilUrl;
    private String idioma;
}

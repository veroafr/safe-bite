package com.safebite.backend.dto.request;

import com.safebite.backend.config.Validaciones;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import lombok.Data;

import java.util.Set;

@Data
public class RegistroRequest {
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    @NotBlank(message = "El email es obligatorio")
    @Email(message = Validaciones.EMAIL_MENSAJE)
    @Pattern(regexp = Validaciones.EMAIL, message = Validaciones.EMAIL_MENSAJE)
    private String email;

    @NotBlank(message = "La contraseña es obligatoria")
    @Pattern(regexp = Validaciones.PASSWORD, message = Validaciones.PASSWORD_MENSAJE)
    private String password;

    private String idioma;
    private String ciudad;
    private String pais;

    /** Codigos de las intolerancias / restricciones alimentarias del usuario. */
    private Set<String> intolerancias;

    /** Opcion "Busco alimentarme mejor". Hay que elegir esto o al menos una intolerancia. */
    private Boolean buscaAlimentacionSaludable;
}

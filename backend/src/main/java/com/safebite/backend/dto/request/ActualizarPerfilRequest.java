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
    private String telefono;
    /** Foto nueva en base64 / data URL. "" = quitar la foto. */
    private String fotoBase64;

    // ---- Solo los usa el administrador (se ignoran en el perfil propio) ----
    private java.util.Set<String> intolerancias;
    private Boolean buscaAlimentacionSaludable;
    private com.safebite.backend.model.NivelAlerta nivelAlerta;
    private java.util.Set<String> tiposCocinaPreferidos;
    private Boolean activo;
    private com.safebite.backend.model.Rol rol;
}

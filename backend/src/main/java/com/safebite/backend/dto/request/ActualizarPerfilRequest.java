package com.safebite.backend.dto.request;

import lombok.Data;

@Data
public class ActualizarPerfilRequest {
    private String nombre;
    private String email;
    private String ciudad;
    private String pais;
    private String fotoPerfilUrl;
    private String idioma;
}

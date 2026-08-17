package com.safebite.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.Set;

@Data
public class NoticiaRequest {
    @NotBlank
    private String titulo;
    private String resumen;
    private String contenido;
    private String imagenUrl;
    private Set<String> etiquetas;
}

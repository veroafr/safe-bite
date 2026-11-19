package com.safebite.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.Set;

@Data
public class RecetaRequest {
    @NotBlank
    private String titulo;
    private String descripcion;
    private Integer tiempoPreparacionMinutos;
    private String dificultad;
    private String imagenUrl;
    private boolean esTip;
    private Set<String> etiquetas;
    /** Codigos de intolerancias para las que la receta es apta. */
    private Set<String> libreDe;
    private List<String> ingredientes;
    private List<String> pasos;
    /** Foto en base64 / data URL (opcional). "" = quitar la foto. */
    private String imagenBase64;
}

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
    private List<String> ingredientes;
    private List<String> pasos;
}

package com.safebite.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class IntoleranciaRequest {
    @NotBlank(message = "El nombre es obligatorio")
    @Size(max = 80, message = "El nombre no puede superar 80 caracteres")
    private String nombre;
    private String nombreCientifico;
    private String descripcion;
    /** Terminos separados por coma para detectarla en ingredientes. Si viene vacio se usa el nombre. */
    private String palabrasClave;
    private Boolean activa;
    private Integer orden;
}

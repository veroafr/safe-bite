package com.safebite.backend.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class EvaluacionRequest {
    @NotNull
    @Min(1)
    @Max(5)
    private Integer puntuacion;
    /** La reseña siempre lleva estrellas y comentario. */
    @jakarta.validation.constraints.NotBlank(message = "Escribí un comentario sobre tu experiencia")
    @jakarta.validation.constraints.Size(min = 10, max = 1000, message = "El comentario debe tener entre 10 y 1000 caracteres")
    private String comentario;
}

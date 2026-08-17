package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoIntolerancia;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.Set;

@Data
public class RestauranteRequest {
    @NotBlank
    private String nombre;
    private String descripcion;
    private String direccion;
    private Double latitud;
    private Double longitud;
    private String imagenUrl;
    private Set<String> tiposCocina;
    private Set<TipoIntolerancia> opcionesAptasPara;
}

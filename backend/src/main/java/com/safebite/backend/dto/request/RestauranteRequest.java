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
    /**
     * Fotos en base64 (o data URL). null = no se cambia; "" = se quita.
     * El servidor las ajusta a 400×400 (miniatura) y 1200×600 (banner).
     */
    private String imagenMiniatura;
    private String imagenBanner;
    private Set<String> tiposCocina;
    private Set<String> opcionesAptasPara;
}

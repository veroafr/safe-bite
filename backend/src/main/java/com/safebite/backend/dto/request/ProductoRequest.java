package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoIntolerancia;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.Set;

@Data
public class ProductoRequest {
    @NotBlank
    private String nombre;
    private String marca;
    private String codigoEan;
    private String imagenUrl;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;

    private Boolean verificado;

    private String fotoFrontalBase64;
    private String fotoComposicionBase64;
    private String fotoNutricionalBase64;
}

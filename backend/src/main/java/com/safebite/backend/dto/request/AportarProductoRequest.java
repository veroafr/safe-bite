package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoIntolerancia;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.Set;

/**
 * Lo que completa un usuario cuando escanea un codigo que no esta en la
 * base ni en Open Food Facts. Queda pendiente de revision por un admin.
 */
@Data
public class AportarProductoRequest {
    @NotBlank
    private String codigoEan;

    @NotBlank
    private String nombre;

    private String marca;
    private String imagenUrl;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;
}

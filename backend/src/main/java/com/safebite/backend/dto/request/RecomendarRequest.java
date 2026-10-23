package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoIntolerancia;
import lombok.Data;

import java.util.List;
import java.util.Set;

/** Producto leido con "Escanear paquete", para pedir alternativas aptas. */
@Data
public class RecomendarRequest {
    private String nombre;
    private String marca;
    private String categoria;
    private String terminoBusquedaEs;
    private String terminoBusquedaPt;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;
}

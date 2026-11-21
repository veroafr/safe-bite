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
    /** Tipo de alimento generico (lo detecta la IA o lo escribe el usuario). */
    private String tipoProducto;
    private String terminoBusquedaEs;
    private String terminoBusquedaPt;
    private List<String> ingredientes;
    private Set<String> alergenos;
    /** Opcional: intolerancias elegidas en el filtro del escaner (si no, se usan las del usuario). */
    private Set<String> intolerancias;
}

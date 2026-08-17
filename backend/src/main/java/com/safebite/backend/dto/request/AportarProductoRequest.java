package com.safebite.backend.dto.request;

import com.safebite.backend.model.TipoIntolerancia;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.util.List;
import java.util.Set;

/**
 * Lo que completa un usuario cuando escanea un codigo que no esta en la
 * base ni en Open Food Facts (POST /aportar), o cuando completa datos
 * insuficientes de un producto que ya existe (PUT /{id}/completar).
 * El nombre no es obligatorio a nivel de validacion porque en el caso de
 * "completar" puede venir vacio (se conserva el nombre que ya tenia el
 * producto); el caso "aportar" valida el nombre a mano en el service.
 */
@Data
public class AportarProductoRequest {
    @NotBlank
    private String codigoEan;

    private String nombre;
    private String marca;
    private String imagenUrl;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;

    private String fotoFrontalBase64;
    private String fotoComposicionBase64;
    private String fotoNutricionalBase64;
}

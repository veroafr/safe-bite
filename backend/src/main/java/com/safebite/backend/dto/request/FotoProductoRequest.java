package com.safebite.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Accion sobre UNA foto puntual de un producto (usado en la bandeja de
 * revision del admin, para poder aceptar/reemplazar/eliminar cada foto
 * por separado sin tocar el resto de los datos del producto).
 *
 * tipo: "frontal" | "composicion" | "nutricional"
 * base64: la nueva imagen (reemplaza), o null/vacio para eliminarla.
 */
@Data
public class FotoProductoRequest {
    @NotBlank
    private String tipo;

    private String base64;
}

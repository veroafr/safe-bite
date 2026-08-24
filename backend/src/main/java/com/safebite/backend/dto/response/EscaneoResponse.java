package com.safebite.backend.dto.response;

import com.safebite.backend.model.TipoIntolerancia;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EscaneoResponse {
    private ProductoResponse producto;
    private boolean seguro;
    private boolean datosSuficientes;
    private Set<TipoIntolerancia> alergenosEnConflicto;
    private String mensaje;

    /**
     * Cuando el producto NO es seguro para el usuario, acá van productos
     * similares (misma categoria) que si son aptos segun sus intolerancias.
     * Vacio si el producto es seguro o no se encontraron alternativas.
     */
    @Builder.Default
    private List<ProductoResponse> alternativas = List.of();
}

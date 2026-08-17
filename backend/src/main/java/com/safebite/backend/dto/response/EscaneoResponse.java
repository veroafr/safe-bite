package com.safebite.backend.dto.response;

import com.safebite.backend.model.TipoIntolerancia;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

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
}
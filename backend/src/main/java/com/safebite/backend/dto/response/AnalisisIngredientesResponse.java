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
public class AnalisisIngredientesResponse {
    private boolean seguro;
    private Set<TipoIntolerancia> alergenosEncontrados;
    private String mensaje;
    private String textoAnalizado;
}
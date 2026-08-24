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
public class AnalisisFotosResponse {
    private String nombreSugerido;
    private String marcaSugerida;
    private String categoriaSugerida;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;
    private boolean pudoLeer;
    private String observacion;
}

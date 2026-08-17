package com.safebite.backend.dto.request;

import com.safebite.backend.model.NivelAlerta;
import com.safebite.backend.model.TipoIntolerancia;
import lombok.Data;

import java.util.Set;

@Data
public class PreferenciasRequest {
    private Set<TipoIntolerancia> intolerancias;
    private NivelAlerta nivelAlerta;
    private Set<String> tiposCocinaPreferidos;
}

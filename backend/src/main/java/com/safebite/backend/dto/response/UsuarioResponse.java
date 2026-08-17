package com.safebite.backend.dto.response;

import com.safebite.backend.model.NivelAlerta;
import com.safebite.backend.model.Rol;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.Set;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UsuarioResponse {
    private Long id;
    private String nombre;
    private String email;
    private String fotoPerfilUrl;
    private String ciudad;
    private String pais;
    private String idioma;
    private Rol rol;
    private Set<TipoIntolerancia> intolerancias;
    private NivelAlerta nivelAlerta;
    private Set<String> tiposCocinaPreferidos;
    private boolean activo;
    private LocalDateTime fechaRegistro;

    public static UsuarioResponse desde(Usuario u) {
        return UsuarioResponse.builder()
                .id(u.getId())
                .nombre(u.getNombre())
                .email(u.getEmail())
                .fotoPerfilUrl(u.getFotoPerfilUrl())
                .ciudad(u.getCiudad())
                .pais(u.getPais())
                .idioma(u.getIdioma())
                .rol(u.getRol())
                .intolerancias(u.getIntolerancias())
                .nivelAlerta(u.getNivelAlerta())
                .tiposCocinaPreferidos(u.getTiposCocinaPreferidos())
                .activo(u.isActivo())
                .fechaRegistro(u.getFechaRegistro())
                .build();
    }
}

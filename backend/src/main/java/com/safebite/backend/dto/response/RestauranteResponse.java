package com.safebite.backend.dto.response;

import com.safebite.backend.model.Restaurante;
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
public class RestauranteResponse {
    private Long id;
    private String nombre;
    private String descripcion;
    private String direccion;
    private Double latitud;
    private Double longitud;
    private String imagenUrl;
    private String imagenMiniatura;
    /** Solo en la ficha del restaurante: en la lista no se envía, para que cargue rápido. */
    private String imagenBanner;
    private Double ratingPromedio;
    private Set<String> tiposCocina;
    private Set<String> opcionesAptasPara;

    /** Versión para la lista: sin el banner. */
    public static RestauranteResponse resumen(Restaurante r) {
        RestauranteResponse res = desde(r);
        res.setImagenBanner(null);
        return res;
    }

    public static RestauranteResponse desde(Restaurante r) {
        return RestauranteResponse.builder()
                .id(r.getId())
                .nombre(r.getNombre())
                .descripcion(r.getDescripcion())
                .direccion(r.getDireccion())
                .latitud(r.getLatitud())
                .longitud(r.getLongitud())
                .imagenUrl(r.getImagenUrl())
                .imagenMiniatura(r.getImagenMiniatura())
                .imagenBanner(r.getImagenBanner())
                .ratingPromedio(r.getRatingPromedio())
                .tiposCocina(r.getTiposCocina())
                .opcionesAptasPara(r.getOpcionesAptasPara())
                .build();
    }
}

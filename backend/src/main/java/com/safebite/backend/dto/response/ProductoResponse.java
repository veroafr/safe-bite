package com.safebite.backend.dto.response;

import com.safebite.backend.model.Producto;
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
public class ProductoResponse {
    private Long id;
    private String nombre;
    private String marca;
    private String codigoEan;
    private String imagenUrl;
    private List<String> ingredientes;
    private Set<TipoIntolerancia> alergenos;

    public static ProductoResponse desde(Producto p) {
        return ProductoResponse.builder()
                .id(p.getId())
                .nombre(p.getNombre())
                .marca(p.getMarca())
                .codigoEan(p.getCodigoEan())
                .imagenUrl(p.getImagenUrl())
                .ingredientes(p.getIngredientes())
                .alergenos(p.getAlergenos())
                .build();
    }
}

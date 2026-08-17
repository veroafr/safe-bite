package com.safebite.backend.dto.response;

import com.safebite.backend.model.OrigenProducto;
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
    private OrigenProducto origen;
    private boolean verificado;
    private String aportadoPorEmail;
    private String fotoFrontalBase64;
    private String fotoComposicionBase64;
    private String fotoNutricionalBase64;

    public static ProductoResponse desde(Producto p) {
        return ProductoResponse.builder()
                .id(p.getId())
                .nombre(p.getNombre())
                .marca(p.getMarca())
                .codigoEan(p.getCodigoEan())
                .imagenUrl(p.getImagenUrl())
                .ingredientes(p.getIngredientes())
                .alergenos(p.getAlergenos())
                .origen(p.getOrigen())
                .verificado(p.isVerificado())
                .aportadoPorEmail(p.getAportadoPorEmail())
                .fotoFrontalBase64(p.getFotoFrontalBase64())
                .fotoComposicionBase64(p.getFotoComposicionBase64())
                .fotoNutricionalBase64(p.getFotoNutricionalBase64())
                .build();
    }
}

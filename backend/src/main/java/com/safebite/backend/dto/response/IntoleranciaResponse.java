package com.safebite.backend.dto.response;

import com.safebite.backend.model.Intolerancia;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class IntoleranciaResponse {
    private Long id;
    private String codigo;
    private String nombre;
    private String nombreCientifico;
    private String descripcion;
    private String palabrasClave;
    private boolean activa;
    private boolean predefinida;
    private Integer orden;

    public static IntoleranciaResponse desde(Intolerancia i) {
        return IntoleranciaResponse.builder()
                .id(i.getId())
                .codigo(i.getCodigo())
                .nombre(i.getNombre())
                .nombreCientifico(i.getNombreCientifico())
                .descripcion(i.getDescripcion())
                .palabrasClave(i.getPalabrasClave())
                .activa(i.isActiva())
                .predefinida(i.isPredefinida())
                .orden(i.getOrden())
                .build();
    }
}

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
public class RecomendacionesResponse {
    private boolean seguro;
    private boolean hayDatos;
    private Set<TipoIntolerancia> alergenosEnConflicto;
    private String mensaje;
    /** true si las explicaciones las redacto la IA; false si es una lista simple por reglas. */
    private boolean conIa;
    private List<Item> recomendaciones;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class Item {
        private String nombre;
        private String marca;
        private String pais;
        private String imagenUrl;
        /** SAFEBITE (base propia verificada) u OPEN_FOOD_FACTS. */
        private String origen;
        private String ean;
        private String motivo;
    }
}

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
    /** true cuando no se sabe que producto es: la app le pide al usuario que lo escriba. */
    private boolean necesitaTipo;
    private Set<String> alergenosEnConflicto;
    private String mensaje;
    /** true si las explicaciones las redacto la IA; false si es una lista simple por reglas. */
    private boolean conIa;
    /** Aviso de revisar el envase (marcas/lotes cambian, contaminacion cruzada). */
    private String advertencia;
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
        /** true si el alergeno depende de la marca o del lote: hay que revisar el envase. */
        private boolean verificarMarca;
        /** Alimento generico en ingles para buscar la imagen ilustrativa (uso interno). */
        @com.fasterxml.jackson.annotation.JsonIgnore
        private String imagenEn;
    }
}

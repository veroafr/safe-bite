package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Intolerancia / alergeno que maneja el sistema. Las predefinidas se
 * siembran al iniciar (ver {@link TipoIntolerancia#PREDEFINIDAS}) y el
 * administrador puede agregar nuevas: apenas se crean aparecen en el
 * registro, en el perfil, en los filtros y en los formularios del admin.
 */
@Entity
@Table(name = "intolerancias")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Intolerancia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Identificador estable (ej: TRIGO). Es lo que se guarda en usuarios, productos, etc. */
    @Column(nullable = false, unique = true, length = 60)
    private String codigo;

    @Column(nullable = false)
    private String nombre;

    private String nombreCientifico;

    @Column(length = 500)
    private String descripcion;

    /** Terminos separados por coma para detectar el alergeno en listas de ingredientes. */
    @Column(length = 2000)
    private String palabrasClave;

    @Builder.Default
    private boolean activa = true;

    /** true = viene de la lista oficial; no se puede borrar, solo desactivar. */
    @Builder.Default
    private boolean predefinida = false;

    @Builder.Default
    private Integer orden = 0;

    @Builder.Default
    private LocalDateTime fechaCreacion = LocalDateTime.now();
}

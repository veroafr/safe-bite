package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

@Entity
@Table(name = "restaurantes")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Restaurante {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(length = 2000)
    private String descripcion;

    private String direccion;

    private Double latitud;

    private Double longitud;

    private String imagenUrl;

    /** Foto cuadrada para la lista (data URL JPEG 400×400). */
    @Column(columnDefinition = "TEXT")
    private String imagenMiniatura;

    /** Foto rectangular 2:1 para la ficha del restaurante (data URL JPEG 1200×600). */
    @Column(columnDefinition = "TEXT")
    private String imagenBanner;

    @Builder.Default
    private Double ratingPromedio = 0.0;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "restaurante_tipos_cocina", joinColumns = @JoinColumn(name = "restaurante_id"))
    @Column(name = "tipo_cocina")
    @Builder.Default
    private Set<String> tiposCocina = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "restaurante_opciones_aptas", joinColumns = @JoinColumn(name = "restaurante_id"))
    @Column(name = "intolerancia")
    @Builder.Default
    private Set<String> opcionesAptasPara = new HashSet<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "creado_por")
    private Usuario creadoPor;

    @Builder.Default
    private boolean activo = true;

    @Builder.Default
    private LocalDateTime fechaCreacion = LocalDateTime.now();
}

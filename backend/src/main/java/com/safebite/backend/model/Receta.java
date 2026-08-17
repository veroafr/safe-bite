package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "recetas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Receta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(length = 2000)
    private String descripcion;

    private Integer tiempoPreparacionMinutos;

    private String dificultad;

    private String imagenUrl;

    private boolean esTip;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "receta_etiquetas", joinColumns = @JoinColumn(name = "receta_id"))
    @Column(name = "etiqueta")
    @Builder.Default
    private Set<String> etiquetas = new HashSet<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "receta_ingredientes", joinColumns = @JoinColumn(name = "receta_id"))
    @Column(name = "ingrediente", length = 500)
    @OrderColumn(name = "orden")
    @Builder.Default
    private List<String> ingredientes = new ArrayList<>();

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "receta_pasos", joinColumns = @JoinColumn(name = "receta_id"))
    @Column(name = "paso", length = 1000)
    @OrderColumn(name = "orden")
    @Builder.Default
    private List<String> pasos = new ArrayList<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "publicado_por")
    private Usuario publicadoPor;

    @Builder.Default
    private LocalDateTime fechaPublicacion = LocalDateTime.now();
}

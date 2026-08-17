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
@Table(name = "productos")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Producto {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    private String marca;

    @Column(unique = true)
    private String codigoEan;

    private String imagenUrl;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "producto_ingredientes", joinColumns = @JoinColumn(name = "producto_id"))
    @Column(name = "ingrediente", length = 300)
    @Builder.Default
    private List<String> ingredientes = new ArrayList<>();

    @ElementCollection(targetClass = TipoIntolerancia.class, fetch = FetchType.EAGER)
    @CollectionTable(name = "producto_alergenos", joinColumns = @JoinColumn(name = "producto_id"))
    @Enumerated(EnumType.STRING)
    @Column(name = "alergeno")
    @Builder.Default
    private Set<TipoIntolerancia> alergenos = new HashSet<>();

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private OrigenProducto origen = OrigenProducto.ADMIN;

    @Builder.Default
    private boolean verificado = true;

    private String aportadoPorEmail;

    @Builder.Default
    private LocalDateTime fechaCreacion = LocalDateTime.now();
}

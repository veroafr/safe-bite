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
@Table(name = "noticias")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Noticia {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String titulo;

    @Column(length = 500)
    private String resumen;

    @Column(length = 5000)
    private String contenido;

    private String imagenUrl;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "noticia_etiquetas", joinColumns = @JoinColumn(name = "noticia_id"))
    @Column(name = "etiqueta")
    @Builder.Default
    private Set<String> etiquetas = new HashSet<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "publicado_por")
    private Usuario publicadoPor;

    @Builder.Default
    private LocalDateTime fechaPublicacion = LocalDateTime.now();
}

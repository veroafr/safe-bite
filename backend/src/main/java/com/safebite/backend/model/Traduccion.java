package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Traducción de un texto de contenido (receta, noticia, mensaje...) guardada para no repetirla. */
@Entity
@Table(name = "traducciones", indexes = @Index(name = "idx_traduccion_clave", columnList = "clave", unique = true))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Traduccion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** SHA-256 de idioma + texto original. */
    @Column(nullable = false, length = 64, unique = true)
    private String clave;

    @Column(nullable = false, length = 2)
    private String idioma;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String original;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String traducido;

    @Builder.Default
    private LocalDateTime fecha = LocalDateTime.now();
}

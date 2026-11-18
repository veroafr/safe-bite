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

    /** Codigos de las intolerancias a las que se refiere la noticia. */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "noticia_intolerancias", joinColumns = @JoinColumn(name = "noticia_id"))
    @Column(name = "intolerancia")
    @Builder.Default
    private Set<String> intolerancias = new HashSet<>();

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "publicado_por")
    private Usuario publicadoPor;

    @Builder.Default
    private LocalDateTime fechaPublicacion = LocalDateTime.now();

    /** MANUAL (la cargó el administrador) o RSS (importada de un medio). */
    @Column(length = 10)
    private String origen;

    /** Medio que publicó la noticia (solo las importadas). */
    private String fuente;

    /** Enlace a la noticia original (solo las importadas). */
    @Column(length = 1500)
    private String urlOriginal;

    /** País de la noticia: UY o BR (solo las importadas). */
    @Column(length = 2)
    private String pais;

    /**
     * Una noticia importada que el administrador borra queda oculta, en
     * lugar de eliminarse, para que la importación no la vuelva a traer.
     */
    private Boolean oculta;

    public boolean esImportada() {
        return "RSS".equals(origen);
    }
}

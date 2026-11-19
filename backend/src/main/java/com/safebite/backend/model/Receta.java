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

    /** Codigos de intolerancias para las que la receta es apta ("libre de trigo", "libre de leche"...). */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "receta_libre_de", joinColumns = @JoinColumn(name = "receta_id"))
    @Column(name = "intolerancia")
    @Builder.Default
    private Set<String> libreDe = new HashSet<>();

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

    // ---- Origen y moderación ----

    /** ADMIN (cargada por el equipo), USUARIO (enviada por una persona) o SPOONACULAR. null = ADMIN. */
    @Column(length = 15)
    private String origen;

    /** PENDIENTE, APROBADA o RECHAZADA. Solo las aprobadas son públicas. null = APROBADA. */
    @Column(length = 12)
    private String estado;

    @Column(length = 500)
    private String motivoRechazo;

    private LocalDateTime fechaRevision;

    /** Foto subida desde la app (data URL JPEG). imagenUrl queda para enlaces externos. */
    @Column(columnDefinition = "TEXT")
    private String imagenDatos;

    /**
     * Recetas de Spoonacular: según sus términos de uso solo se guardan el id,
     * el título y la URL de la imagen. Ingredientes y pasos se piden en vivo
     * cada vez que alguien abre la receta (y se traducen en ese momento).
     */
    private Long externoId;

    @Column(length = 500)
    private String tituloOriginal;

    public static final String ORIGEN_ADMIN = "ADMIN";
    public static final String ORIGEN_USUARIO = "USUARIO";
    public static final String ORIGEN_SPOONACULAR = "SPOONACULAR";
    public static final String PENDIENTE = "PENDIENTE";
    public static final String APROBADA = "APROBADA";
    public static final String RECHAZADA = "RECHAZADA";

    public String origenEfectivo() { return origen == null ? ORIGEN_ADMIN : origen; }
    public String estadoEfectivo() { return estado == null ? APROBADA : estado; }
    public boolean estaPublicada() { return APROBADA.equals(estadoEfectivo()); }
    public boolean esDeSpoonacular() { return ORIGEN_SPOONACULAR.equals(origen); }
}

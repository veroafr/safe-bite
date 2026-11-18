package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "alertas")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Alerta {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TipoAlerta tipo;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "restaurante_id")
    private Restaurante restaurante;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "producto_id")
    private Producto producto;

    @Column(nullable = false, length = 1000)
    private String descripcion;

    /** Teléfono para que el equipo contacte a quien reporta. */
    @Column(length = 30)
    private String telefonoContacto;

    /** Pruebas opcionales (fotos) como data URL JPEG, máximo 3. */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "alerta_pruebas", joinColumns = @JoinColumn(name = "alerta_id"))
    @Column(name = "imagen", columnDefinition = "TEXT")
    @OrderColumn(name = "orden")
    @Builder.Default
    private java.util.List<String> pruebas = new java.util.ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private EstadoAlerta estado = EstadoAlerta.PENDIENTE;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "revisado_por")
    private Usuario revisadoPor;

    @Builder.Default
    private LocalDateTime fecha = LocalDateTime.now();

    private LocalDateTime fechaRevision;
}

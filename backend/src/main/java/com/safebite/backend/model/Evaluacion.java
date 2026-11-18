package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Entity
@Table(name = "evaluaciones", uniqueConstraints = @UniqueConstraint(columnNames = {"restaurante_id", "usuario_id"}))
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Evaluacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "restaurante_id")
    private Restaurante restaurante;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    @Column(nullable = false)
    private Integer puntuacion;

    @Column(length = 1000)
    private String comentario;

    @Builder.Default
    private LocalDateTime fecha = LocalDateTime.now();

    /**
     * PENDIENTE (recién enviada), APROBADA (visible para todos) o RECHAZADA.
     * Las reseñas solo se publican cuando el administrador las aprueba.
     * Las anteriores a este cambio (null) se consideran aprobadas.
     */
    @Column(length = 12)
    private String estado;

    /** Motivo que el administrador indica al rechazar (lo ve el autor). */
    @Column(length = 500)
    private String motivoRechazo;

    private LocalDateTime fechaRevision;

    public static final String PENDIENTE = "PENDIENTE";
    public static final String APROBADA = "APROBADA";
    public static final String RECHAZADA = "RECHAZADA";

    public boolean estaPublicada() {
        return estado == null || APROBADA.equals(estado);
    }
}

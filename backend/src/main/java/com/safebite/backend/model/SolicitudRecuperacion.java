package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * Pedido de "olvidé mi contraseña". No se envía nada automático: el pedido
 * aparece en el panel de administración y el administrador le asigna una
 * contraseña temporal y se comunica con la persona por el contacto indicado.
 */
@Entity
@Table(name = "solicitudes_recuperacion")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SolicitudRecuperacion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** Email tal como lo escribió la persona. */
    @Column(nullable = false)
    private String email;

    /** Cuenta encontrada con ese email (null si no existe). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "usuario_id")
    private Usuario usuario;

    /** Teléfono / WhatsApp para avisarle la contraseña nueva (opcional). */
    @Column(length = 40)
    private String telefono;

    @Column(length = 500)
    private String mensaje;

    /** PENDIENTE, RESUELTA o DESCARTADA. */
    @Column(nullable = false, length = 12)
    @Builder.Default
    private String estado = PENDIENTE;

    @Builder.Default
    private LocalDateTime fecha = LocalDateTime.now();

    private LocalDateTime fechaResolucion;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resuelta_por")
    private Usuario resueltaPor;

    @Column(length = 500)
    private String nota;

    public static final String PENDIENTE = "PENDIENTE";
    public static final String RESUELTA = "RESUELTA";
    public static final String DESCARTADA = "DESCARTADA";
}

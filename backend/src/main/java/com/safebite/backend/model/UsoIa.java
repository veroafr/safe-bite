package com.safebite.backend.model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/** Una llamada a un proveedor de IA, para llevar la cuenta del gasto estimado. */
@Entity
@Table(name = "uso_ia")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UsoIa {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Builder.Default
    private LocalDateTime fecha = LocalDateTime.now();

    /** CLAUDE o GEMINI. */
    private String proveedor;

    /** LECTURA_PAQUETE, RECOMENDACION, etc. */
    private String operacion;

    private int tokensEntrada;
    private int tokensSalida;

    /** Costo estimado en USD (Gemini free tier = 0). */
    private double costoUsd;
}

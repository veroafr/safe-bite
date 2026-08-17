package com.safebite.backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReporteResponse {
    private long totalUsuarios;
    private long totalRestaurantes;
    private long totalRecetas;
    private long totalNoticias;
    private long totalProductos;
    private long alertasPendientes;
    private long alertasAceptadas;
    private long alertasDenegadas;
}

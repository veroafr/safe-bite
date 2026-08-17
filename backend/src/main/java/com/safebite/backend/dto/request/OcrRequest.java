package com.safebite.backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * Simula el resultado de un lector OCR: el cliente (app Flutter) hace el
 * reconocimiento de texto sobre la foto del empaque y envia el texto
 * detectado; el backend intenta emparejarlo con un producto conocido.
 */
@Data
public class OcrRequest {
    @NotBlank
    private String textoDetectado;
}

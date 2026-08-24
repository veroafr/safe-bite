package com.safebite.backend.dto.request;

import lombok.Data;

/** Fotos (base64) a analizar con IA de vision. Las 3 son opcionales, se manda al menos una. */
@Data
public class AnalizarFotosRequest {
    private String fotoFrontalBase64;
    private String fotoComposicionBase64;
    private String fotoNutricionalBase64;
}

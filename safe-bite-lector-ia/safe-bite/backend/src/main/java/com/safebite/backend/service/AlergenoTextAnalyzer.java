package com.safebite.backend.service;

import com.safebite.backend.model.Intolerancia;
import com.safebite.backend.repository.IntoleranciaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Detecta alergenos en un texto libre (lista de ingredientes) usando las
 * palabras clave de cada intolerancia guardada en la base. Asi, cuando el
 * administrador agrega una intolerancia nueva con sus palabras clave, el
 * analizador ya la reconoce sin tocar codigo.
 *
 * Reglas:
 *  - se compara sin acentos ni mayusculas y tratando guiones como espacios;
 *  - la palabra clave tiene que aparecer como palabra completa (acepta plural -s / -es),
 *    para que "ovo" no matchee "novo" ni "soja" matchee "sojarrr";
 *  - se ignoran menciones negadas: "sin gluten", "sem lactose", "libre de leche",
 *    "isento de ...", "gluten free".
 */
@Component
@RequiredArgsConstructor
public class AlergenoTextAnalyzer {

    private static final Pattern NEGACION_ANTES = Pattern.compile("(?:\\bsin|\\bsem|\\blibre de|\\blivre de|\\bisento de|\\bexento de|\\bzero)\\s+$");
    private static final Pattern NEGACION_DESPUES = Pattern.compile("^\\s+free\\b");

    private final IntoleranciaRepository intoleranciaRepository;

    public Set<String> detectar(String texto) {
        Set<String> encontrados = new HashSet<>();
        if (texto == null || texto.isBlank()) {
            return encontrados;
        }
        String normalizado = normalizar(texto);
        List<Intolerancia> activas = intoleranciaRepository.findByActivaTrueOrderByOrdenAscNombreAsc();

        for (Intolerancia intolerancia : activas) {
            String claves = intolerancia.getPalabrasClave();
            if (claves == null || claves.isBlank()) claves = intolerancia.getNombre();
            for (String palabra : claves.split(",")) {
                String p = normalizar(palabra);
                if (p.isEmpty()) continue;
                if (aparece(normalizado, p)) {
                    encontrados.add(intolerancia.getCodigo());
                    break;
                }
            }
        }
        return encontrados;
    }

    private boolean aparece(String texto, String palabra) {
        Pattern patron = Pattern.compile("(?<![a-z0-9])" + Pattern.quote(palabra) + "(?:s|es)?(?![a-z0-9])");
        Matcher m = patron.matcher(texto);
        while (m.find()) {
            String antes = texto.substring(Math.max(0, m.start() - 14), m.start());
            String despues = texto.substring(m.end(), Math.min(texto.length(), m.end() + 6));
            if (NEGACION_ANTES.matcher(antes).find() || NEGACION_DESPUES.matcher(despues).find()) {
                continue; // "sin gluten", "gluten free": no indica presencia
            }
            return true;
        }
        return false;
    }

    private String normalizar(String texto) {
        String sinAcentos = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return sinAcentos.toLowerCase().replace('-', ' ').replaceAll("\\s+", " ").trim();
    }
}

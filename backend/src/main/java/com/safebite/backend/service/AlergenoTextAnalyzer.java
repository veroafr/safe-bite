package com.safebite.backend.service;

import com.safebite.backend.model.TipoIntolerancia;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Component
public class AlergenoTextAnalyzer {

    private static final Map<TipoIntolerancia, List<String>> DICCIONARIO = Map.of(
            TipoIntolerancia.GLUTEN, List.of(
                    "gluten", "trigo", "harina de trigo", "farinha de trigo", "farinha",
                    "cevada", "cebada", "centeio", "centeno", "malta", "avena", "aveia"
            ),
            TipoIntolerancia.LACTOSA, List.of(
                    "leche", "leite", "milk", "lactosa", "lactose", "manteiga", "mantequilla",
                    "queso", "queijo", "crema de leche", "creme de leite", "nata",
                    "suero de leche", "soro de leite", "yogur", "iogurte", "caseina", "whey"
            ),
            TipoIntolerancia.FRUTOS_SECOS, List.of(
                    "mani", "cacahuete", "cacahuate", "amendoim", "almendra", "amendoa",
                    "nuez", "nueces", "noz", "nozes", "avellana", "avela", "castanha",
                    "castana", "pistacho", "pistache", "macadamia", "nuts"
            ),
            TipoIntolerancia.MARISCOS, List.of(
                    "camaron", "camarao", "langosta", "lagosta", "cangrejo", "caranguejo",
                    "mejillon", "mexilhao", "mariscos", "crustaceos", "moluscos", "ostra",
                    "ostion", "calamar", "lula"
            )
    );

    public Set<TipoIntolerancia> detectar(String texto) {
        Set<TipoIntolerancia> encontrados = new HashSet<>();
        if (texto == null || texto.isBlank()) {
            return encontrados;
        }
        String normalizado = normalizar(texto);

        for (Map.Entry<TipoIntolerancia, List<String>> entry : DICCIONARIO.entrySet()) {
            for (String palabra : entry.getValue()) {
                if (normalizado.contains(normalizar(palabra))) {
                    encontrados.add(entry.getKey());
                    break;
                }
            }
        }
        return encontrados;
    }

    private String normalizar(String texto) {
        String sinAcentos = Normalizer.normalize(texto, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "");
        return sinAcentos.toLowerCase();
    }
}
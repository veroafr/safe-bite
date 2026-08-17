package com.safebite.backend.service;

import com.safebite.backend.model.TipoIntolerancia;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class OpenFoodFactsService {

    private static final String BASE_URL = "https://world.openfoodfacts.org/api/v2/product/";
    private static final String FIELDS = "product_name,brands,image_url,ingredients_text,allergens_tags,traces_tags";

    private final RestTemplate restTemplate;
    private final AlergenoTextAnalyzer alergenoTextAnalyzer;

    public record ProductoExterno(
            String nombre,
            String marca,
            String imagenUrl,
            List<String> ingredientes,
            Set<TipoIntolerancia> alergenos
    ) {}

    @SuppressWarnings("unchecked")
    public Optional<ProductoExterno> buscarPorEan(String codigoEan) {
        String url = BASE_URL + codigoEan + ".json?fields=" + FIELDS;

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent", "SafeBiteApp/1.0 (contacto@safebite.com)");
            HttpEntity<Void> entity = new HttpEntity<>(headers);

            ResponseEntity<Map> response = restTemplate.exchange(url, HttpMethod.GET, entity, Map.class);
            Map<String, Object> body = response.getBody();

            if (body == null || !"1".equals(String.valueOf(body.get("status")))) {
                return Optional.empty();
            }

            Map<String, Object> producto = (Map<String, Object>) body.get("product");
            if (producto == null) {
                return Optional.empty();
            }

            String nombre = (String) producto.get("product_name");
            if (nombre == null || nombre.isBlank()) {
                return Optional.empty();
            }

            String marca = (String) producto.get("brands");
            String imagenUrl = (String) producto.get("image_url");
            String ingredientesTexto = (String) producto.get("ingredients_text");

            List<String> ingredientes = new ArrayList<>();
            if (ingredientesTexto != null && !ingredientesTexto.isBlank()) {
                for (String parte : ingredientesTexto.split(",")) {
                    String limpio = parte.trim();
                    if (!limpio.isEmpty()) ingredientes.add(limpio);
                }
            }

            List<String> tagsAlergenos = (List<String>) producto.getOrDefault("allergens_tags", List.of());
            Set<TipoIntolerancia> alergenos = new java.util.HashSet<>(mapearAlergenos(tagsAlergenos));

            List<String> tagsTrazas = (List<String>) producto.getOrDefault("traces_tags", List.of());
            alergenos.addAll(mapearAlergenos(tagsTrazas));

            alergenos.addAll(alergenoTextAnalyzer.detectar(ingredientesTexto));

            return Optional.of(new ProductoExterno(nombre, marca, imagenUrl, ingredientes, alergenos));

        } catch (Exception e) {
            log.warn("No se pudo consultar Open Food Facts para el EAN {}: {}", codigoEan, e.getMessage());
            return Optional.empty();
        }
    }

    private Set<TipoIntolerancia> mapearAlergenos(List<String> tags) {
        Set<TipoIntolerancia> resultado = new HashSet<>();
        for (String tag : tags) {
            String t = tag.toLowerCase();
            if (t.contains("gluten")) {
                resultado.add(TipoIntolerancia.GLUTEN);
            } else if (t.contains("milk") || t.contains("lactose")) {
                resultado.add(TipoIntolerancia.LACTOSA);
            } else if (t.contains("nuts") || t.contains("peanuts")) {
                resultado.add(TipoIntolerancia.FRUTOS_SECOS);
            } else if (t.contains("crustaceans") || t.contains("molluscs") || t.contains("fish")) {
                resultado.add(TipoIntolerancia.MARISCOS);
            }
        }
        return resultado;
    }
}
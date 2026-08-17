package com.safebite.backend.config;

import com.safebite.backend.model.*;
import com.safebite.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Set;

/**
 * Carga datos de ejemplo al iniciar la aplicacion (solo si la base esta
 * vacia) para poder probar la app Flutter contra el backend sin tener que
 * cargar datos manualmente.
 */
@Component
@RequiredArgsConstructor
public class DataSeeder implements CommandLineRunner {

    private final UsuarioRepository usuarioRepository;
    private final RestauranteRepository restauranteRepository;
    private final RecetaRepository recetaRepository;
    private final NoticiaRepository noticiaRepository;
    private final ProductoRepository productoRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) {
        if (usuarioRepository.count() > 0) {
            return;
        }

        Usuario admin = usuarioRepository.save(Usuario.builder()
                .nombre("Administrador Safe-Bite")
                .email("admin@safebite.com")
                .password(passwordEncoder.encode("admin123"))
                .rol(Rol.ADMINISTRADOR)
                .ciudad("Buenos Aires")
                .pais("Argentina")
                .build());

        usuarioRepository.save(Usuario.builder()
                .nombre("Maria Gonzalez")
                .email("maria@email.com")
                .password(passwordEncoder.encode("usuario123"))
                .rol(Rol.USUARIO)
                .ciudad("Buenos Aires")
                .pais("Argentina")
                .intolerancias(Set.of(TipoIntolerancia.GLUTEN, TipoIntolerancia.FRUTOS_SECOS))
                .nivelAlerta(NivelAlerta.ALTO)
                .tiposCocinaPreferidos(Set.of("Vegana", "Sin Gluten"))
                .build());

        Restaurante r1 = restauranteRepository.save(Restaurante.builder()
                .nombre("Restaurante Saludable")
                .descripcion("Opciones sin gluten disponibles, cocina casera y fresca")
                .direccion("Av. Corrientes 1234, CABA")
                .latitud(-34.6037)
                .longitud(-58.3816)
                .imagenUrl("https://picsum.photos/seed/restaurante1/400/300")
                .tiposCocina(Set.of("Casera", "Saludable"))
                .opcionesAptasPara(Set.of(TipoIntolerancia.GLUTEN))
                .ratingPromedio(4.2)
                .creadoPor(admin)
                .build());

        restauranteRepository.save(Restaurante.builder()
                .nombre("Cafe Verde")
                .descripcion("Menu vegano completo, opciones sin lactosa")
                .direccion("Av. Santa Fe 4321, CABA")
                .latitud(-34.5895)
                .longitud(-58.3974)
                .imagenUrl("https://picsum.photos/seed/restaurante2/400/300")
                .tiposCocina(Set.of("Vegana", "Cafeteria"))
                .opcionesAptasPara(Set.of(TipoIntolerancia.LACTOSA, TipoIntolerancia.GLUTEN))
                .ratingPromedio(4.8)
                .creadoPor(admin)
                .build());

        recetaRepository.save(Receta.builder()
                .titulo("Pasta Sin Gluten")
                .descripcion("Una pasta casera apta para celiacos, lista en minutos")
                .tiempoPreparacionMinutos(15)
                .dificultad("Facil")
                .imagenUrl("https://picsum.photos/seed/receta1/400/300")
                .etiquetas(Set.of("Sin Gluten"))
                .ingredientes(List.of("200g harina sin TACC", "2 huevos", "Sal", "Aceite de oliva"))
                .pasos(List.of("Mezclar los ingredientes", "Amasar 10 minutos", "Cocinar en agua hirviendo 3-4 minutos"))
                .publicadoPor(admin)
                .build());

        recetaRepository.save(Receta.builder()
                .titulo("Smoothie Verde")
                .descripcion("Batido energizante apto para veganos")
                .tiempoPreparacionMinutos(5)
                .dificultad("Muy Facil")
                .imagenUrl("https://picsum.photos/seed/receta2/400/300")
                .etiquetas(Set.of("Vegano"))
                .ingredientes(List.of("1 banana", "Espinaca", "Leche de almendras", "Miel"))
                .pasos(List.of("Colocar todo en la licuadora", "Procesar 1 minuto", "Servir frio"))
                .publicadoPor(admin)
                .build());

        recetaRepository.save(Receta.builder()
                .titulo("Galletas de Avena")
                .descripcion("Galletas caseras sin lactosa")
                .tiempoPreparacionMinutos(25)
                .dificultad("Medio")
                .imagenUrl("https://picsum.photos/seed/receta3/400/300")
                .etiquetas(Set.of("Sin Lactosa"))
                .ingredientes(List.of("Avena", "Aceite de coco", "Azucar mascabo", "Pasas de uva"))
                .pasos(List.of("Mezclar ingredientes secos", "Incorporar aceite", "Hornear 15 minutos a 180C"))
                .publicadoPor(admin)
                .build());

        recetaRepository.save(Receta.builder()
                .titulo("Sopa de Verduras")
                .descripcion("Sopa liviana apta para veganos")
                .tiempoPreparacionMinutos(30)
                .dificultad("Facil")
                .imagenUrl("https://picsum.photos/seed/receta4/400/300")
                .etiquetas(Set.of("Vegano"))
                .ingredientes(List.of("Zanahoria", "Papa", "Apio", "Caldo de verduras"))
                .pasos(List.of("Cortar las verduras", "Hervir 20 minutos", "Procesar y servir"))
                .publicadoPor(admin)
                .build());

        noticiaRepository.save(Noticia.builder()
                .titulo("Nuevos restaurantes libres de gluten en la ciudad")
                .resumen("Cinco nuevas propuestas gastronomicas 100% aptas para celiacos")
                .contenido("Este mes se sumaron cinco nuevos restaurantes a nuestra red de locales certificados libres de gluten...")
                .imagenUrl("https://picsum.photos/seed/noticia1/400/300")
                .etiquetas(Set.of("Gluten"))
                .publicadoPor(admin)
                .build());

        noticiaRepository.save(Noticia.builder()
                .titulo("Tips para leer etiquetas de alergenos")
                .resumen("Aprende a identificar rapidamente los alergenos ocultos en los envases")
                .contenido("Muchas veces los alergenos aparecen bajo nombres tecnicos poco conocidos...")
                .imagenUrl("https://picsum.photos/seed/noticia2/400/300")
                .etiquetas(Set.of("Alergenos"))
                .publicadoPor(admin)
                .build());

        productoRepository.save(Producto.builder()
                .nombre("Galletitas de Arroz")
                .marca("NaturSnack")
                .codigoEan("123456789")
                .imagenUrl("https://picsum.photos/seed/producto1/400/300")
                .ingredientes(List.of("Arroz integral", "Aceite de girasol", "Sal"))
                .alergenos(Set.of(TipoIntolerancia.GLUTEN))
                .build());

        productoRepository.save(Producto.builder()
                .nombre("Leche de Almendras")
                .marca("VeganMilk")
                .codigoEan("987654321")
                .imagenUrl("https://picsum.photos/seed/producto2/400/300")
                .ingredientes(List.of("Agua", "Almendras", "Sal marina"))
                .alergenos(Set.of(TipoIntolerancia.FRUTOS_SECOS))
                .build());
    }
}

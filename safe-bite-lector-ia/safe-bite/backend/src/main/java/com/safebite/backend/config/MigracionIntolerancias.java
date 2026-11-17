package com.safebite.backend.config;

import com.safebite.backend.model.Noticia;
import com.safebite.backend.model.Producto;
import com.safebite.backend.model.Receta;
import com.safebite.backend.model.Restaurante;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.NoticiaRepository;
import com.safebite.backend.repository.ProductoRepository;
import com.safebite.backend.repository.RecetaRepository;
import com.safebite.backend.repository.RestauranteRepository;
import com.safebite.backend.repository.UsuarioRepository;
import com.safebite.backend.service.IntoleranciaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.sql.Connection;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Pasa los datos del modelo viejo (enum GLUTEN / LACTOSA / FRUTOS_SECOS /
 * MARISCOS) al modelo nuevo de intolerancias dinamicas. Es idempotente: se
 * puede ejecutar en cada arranque.
 *
 * 1) En PostgreSQL, Hibernate 6 creaba restricciones CHECK sobre las columnas
 *    del enum (ej: intolerancia in ('GLUTEN',...)). Con ddl-auto=update no se
 *    borran solas e impedirian guardar codigos nuevos como TRIGO, asi que se eliminan.
 * 2) Siembra las intolerancias predefinidas.
 * 3) Traduce los codigos viejos guardados en usuarios, productos y restaurantes,
 *    y las etiquetas "Sin Gluten"/"Sin Lactosa"... de recetas al campo libreDe.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class MigracionIntolerancias {

    private static final List<String> TABLAS_CON_ENUM = List.of(
            "usuario_intolerancias", "producto_alergenos", "restaurante_opciones_aptas");

    private final JdbcTemplate jdbcTemplate;
    private final IntoleranciaService intoleranciaService;
    private final UsuarioRepository usuarioRepository;
    private final ProductoRepository productoRepository;
    private final RestauranteRepository restauranteRepository;
    private final RecetaRepository recetaRepository;
    private final NoticiaRepository noticiaRepository;

    public void ejecutar() {
        quitarChecksDelEnum();
        intoleranciaService.sembrarPredefinidas();
        migrarDatos();
    }

    private void quitarChecksDelEnum() {
        try {
            String motor = jdbcTemplate.execute((Connection c) -> c.getMetaData().getDatabaseProductName());
            if (motor == null || !motor.toLowerCase().contains("postgres")) return;
            for (String tabla : TABLAS_CON_ENUM) {
                List<String> checks = jdbcTemplate.queryForList("""
                        SELECT con.conname FROM pg_constraint con
                        JOIN pg_class rel ON rel.oid = con.conrelid
                        WHERE con.contype = 'c' AND rel.relname = ?
                        """, String.class, tabla);
                for (String check : checks) {
                    jdbcTemplate.execute("ALTER TABLE " + tabla + " DROP CONSTRAINT IF EXISTS \"" + check + "\"");
                    log.info("Eliminada restriccion {} de {} (enum de intolerancias viejo)", check, tabla);
                }
            }
        } catch (Exception e) {
            log.warn("No se pudieron revisar las restricciones del enum viejo: {}", e.getMessage());
        }
    }

    private void migrarDatos() {
        for (Usuario u : usuarioRepository.findAll()) {
            Set<String> nuevos = traducir(u.getIntolerancias());
            if (nuevos != null) {
                u.setIntolerancias(nuevos);
                usuarioRepository.save(u);
            }
        }
        for (Producto p : productoRepository.findAll()) {
            Set<String> nuevos = traducir(p.getAlergenos());
            if (nuevos != null) {
                p.setAlergenos(nuevos);
                productoRepository.save(p);
            }
        }
        for (Restaurante r : restauranteRepository.findAll()) {
            Set<String> nuevos = traducir(r.getOpcionesAptasPara());
            if (nuevos != null) {
                r.setOpcionesAptasPara(nuevos);
                restauranteRepository.save(r);
            }
        }
        Map<String, String> etiquetaAGrupo = Map.of(
                "sin gluten", "GLUTEN", "sin tacc", "GLUTEN", "sin lactosa", "LACTOSA",
                "sin frutos secos", "FRUTOS_SECOS", "sin mariscos", "MARISCOS");
        for (Receta r : recetaRepository.findAll()) {
            if (r.getLibreDe() != null && !r.getLibreDe().isEmpty()) continue;
            Set<String> libreDe = new HashSet<>();
            for (String e : r.getEtiquetas()) {
                String grupo = e == null ? null : etiquetaAGrupo.get(e.trim().toLowerCase());
                if (grupo != null) libreDe.addAll(TipoIntolerancia.LEGADO.get(grupo));
            }
            if (!libreDe.isEmpty()) {
                r.setLibreDe(libreDe);
                recetaRepository.save(r);
            }
        }
        Map<String, String> temaAGrupo = Map.of(
                "gluten", "GLUTEN", "celiaquia", "GLUTEN", "lactosa", "LACTOSA",
                "frutos secos", "FRUTOS_SECOS", "mariscos", "MARISCOS");
        for (Noticia n : noticiaRepository.findAll()) {
            if (n.getIntolerancias() != null && !n.getIntolerancias().isEmpty()) continue;
            Set<String> temas = new HashSet<>();
            for (String e : n.getEtiquetas()) {
                String grupo = e == null ? null : temaAGrupo.get(e.trim().toLowerCase());
                if (grupo != null) temas.addAll(TipoIntolerancia.LEGADO.get(grupo));
            }
            if (!temas.isEmpty()) {
                n.setIntolerancias(temas);
                noticiaRepository.save(n);
            }
        }
    }

    /** null si no hay nada que cambiar; si no, el conjunto con los codigos viejos traducidos. */
    private Set<String> traducir(Set<String> codigos) {
        if (codigos == null || codigos.stream().noneMatch(TipoIntolerancia.LEGADO::containsKey)) return null;
        Set<String> r = new HashSet<>();
        for (String c : codigos) {
            r.addAll(TipoIntolerancia.LEGADO.getOrDefault(c, Set.of(c)));
        }
        return r;
    }
}

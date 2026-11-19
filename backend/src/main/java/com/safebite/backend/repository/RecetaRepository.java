package com.safebite.backend.repository;

import com.safebite.backend.model.Receta;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecetaRepository extends JpaRepository<Receta, Long> {
    java.util.List<Receta> findByEsTip(boolean esTip);
    java.util.List<Receta> findByEstadoOrderByFechaPublicacionAsc(String estado);
    java.util.List<Receta> findByPublicadoPorIdAndOrigenOrderByFechaPublicacionDesc(Long usuarioId, String origen);
    java.util.Optional<Receta> findFirstByExternoIdAndOrigen(Long externoId, String origen);
    java.util.List<Receta> findByOrigen(String origen);
}

package com.safebite.backend.repository;

import com.safebite.backend.model.Evaluacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EvaluacionRepository extends JpaRepository<Evaluacion, Long> {
    List<Evaluacion> findByRestauranteIdOrderByFechaDesc(Long restauranteId);
    Optional<Evaluacion> findByRestauranteIdAndUsuarioId(Long restauranteId, Long usuarioId);

    /** Promedio solo de las reseñas publicadas (aprobadas o anteriores a la moderación). */
    @org.springframework.data.jpa.repository.Query("select avg(e.puntuacion) from Evaluacion e where e.restaurante.id = :restauranteId and (e.estado is null or e.estado = 'APROBADA')")
    Double promedioPorRestaurante(Long restauranteId);

    List<Evaluacion> findByEstadoOrderByFechaAsc(String estado);
}

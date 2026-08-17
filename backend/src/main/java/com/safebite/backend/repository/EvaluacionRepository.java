package com.safebite.backend.repository;

import com.safebite.backend.model.Evaluacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EvaluacionRepository extends JpaRepository<Evaluacion, Long> {
    List<Evaluacion> findByRestauranteIdOrderByFechaDesc(Long restauranteId);
    Optional<Evaluacion> findByRestauranteIdAndUsuarioId(Long restauranteId, Long usuarioId);

    @org.springframework.data.jpa.repository.Query("select avg(e.puntuacion) from Evaluacion e where e.restaurante.id = :restauranteId")
    Double promedioPorRestaurante(Long restauranteId);
}

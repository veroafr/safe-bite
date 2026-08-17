package com.safebite.backend.repository;

import com.safebite.backend.model.Comentario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ComentarioRepository extends JpaRepository<Comentario, Long> {
    List<Comentario> findByRestauranteIdOrderByFechaDesc(Long restauranteId);
}

package com.safebite.backend.repository;

import com.safebite.backend.model.Alerta;
import com.safebite.backend.model.EstadoAlerta;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AlertaRepository extends JpaRepository<Alerta, Long> {
    List<Alerta> findByUsuarioIdOrderByFechaDesc(Long usuarioId);
    List<Alerta> findByEstadoOrderByFechaDesc(EstadoAlerta estado);
    long countByEstado(EstadoAlerta estado);
}

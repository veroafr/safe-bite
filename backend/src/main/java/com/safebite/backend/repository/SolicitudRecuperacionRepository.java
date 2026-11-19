package com.safebite.backend.repository;

import com.safebite.backend.model.SolicitudRecuperacion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface SolicitudRecuperacionRepository extends JpaRepository<SolicitudRecuperacion, Long> {
    List<SolicitudRecuperacion> findByEstadoOrderByFechaDesc(String estado);
    List<SolicitudRecuperacion> findAllByOrderByFechaDesc();
    Optional<SolicitudRecuperacion> findFirstByEmailIgnoreCaseAndEstado(String email, String estado);
    long countByEstado(String estado);
}

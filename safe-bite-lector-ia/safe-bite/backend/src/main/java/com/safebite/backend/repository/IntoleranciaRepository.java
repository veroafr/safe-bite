package com.safebite.backend.repository;

import com.safebite.backend.model.Intolerancia;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface IntoleranciaRepository extends JpaRepository<Intolerancia, Long> {
    Optional<Intolerancia> findByCodigo(String codigo);
    boolean existsByCodigo(String codigo);
    boolean existsByNombreIgnoreCase(String nombre);
    List<Intolerancia> findAllByOrderByOrdenAscNombreAsc();
    List<Intolerancia> findByActivaTrueOrderByOrdenAscNombreAsc();
}

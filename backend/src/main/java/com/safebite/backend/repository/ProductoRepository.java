package com.safebite.backend.repository;

import com.safebite.backend.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProductoRepository extends JpaRepository<Producto, Long> {
    Optional<Producto> findByCodigoEan(String codigoEan);
    List<Producto> findByNombreContainingIgnoreCase(String nombre);
    List<Producto> findByVerificadoFalseOrderByFechaCreacionDesc();
}

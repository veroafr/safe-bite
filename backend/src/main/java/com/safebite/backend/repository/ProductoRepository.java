package com.safebite.backend.repository;

import com.safebite.backend.model.Producto;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface ProductoRepository extends JpaRepository<Producto, Long> {
    Optional<Producto> findByCodigoEan(String codigoEan);
    List<Producto> findByNombreContainingIgnoreCase(String nombre);
    List<Producto> findByVerificadoFalseOrderByFechaCreacionDesc();

    /** Candidatos a alternativa: misma categoria, verificados, no el mismo producto. */
    List<Producto> findByVerificadoTrueAndCategoriaIgnoreCaseAndIdNot(String categoria, Long id);

    /** Fallback cuando el producto no tiene categoria cargada: todos los verificados. */
    List<Producto> findByVerificadoTrueAndIdNot(Long id);
}

package com.safebite.backend.repository;

import com.safebite.backend.model.Receta;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RecetaRepository extends JpaRepository<Receta, Long> {
    java.util.List<Receta> findByEsTip(boolean esTip);
}

package com.safebite.backend.repository;

import com.safebite.backend.model.Traduccion;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;

public interface TraduccionRepository extends JpaRepository<Traduccion, Long> {
    List<Traduccion> findByClaveIn(Collection<String> claves);
}

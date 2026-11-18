package com.safebite.backend.repository;

import com.safebite.backend.model.Noticia;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface NoticiaRepository extends JpaRepository<Noticia, Long> {

    boolean existsByUrlOriginal(String urlOriginal);

    boolean existsByTituloIgnoreCase(String titulo);

    /** Importadas más viejas que la fecha dada (para limpiar las antiguas). */
    List<Noticia> findByOrigenAndFechaPublicacionBefore(String origen, LocalDateTime fecha);
}

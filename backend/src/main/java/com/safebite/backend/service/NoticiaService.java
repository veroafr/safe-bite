package com.safebite.backend.service;

import com.safebite.backend.dto.request.NoticiaRequest;
import com.safebite.backend.dto.response.NoticiaResponse;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Noticia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.NoticiaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
public class NoticiaService {

    private final NoticiaRepository noticiaRepository;

    public List<NoticiaResponse> listar(String etiqueta) {
        List<Noticia> noticias = noticiaRepository.findAll();
        return noticias.stream()
                .filter(n -> etiqueta == null || etiqueta.isBlank()
                        || n.getEtiquetas().stream().anyMatch(e -> e.equalsIgnoreCase(etiqueta)))
                .sorted(Comparator.comparing(Noticia::getFechaPublicacion).reversed())
                .map(NoticiaResponse::desde)
                .toList();
    }

    public NoticiaResponse obtener(Long id) {
        return NoticiaResponse.desde(buscarEntidad(id));
    }

    public Noticia buscarEntidad(Long id) {
        return noticiaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Noticia no encontrada"));
    }

    @Transactional
    public NoticiaResponse crear(NoticiaRequest request, Usuario admin) {
        Noticia noticia = Noticia.builder()
                .titulo(request.getTitulo())
                .resumen(request.getResumen())
                .contenido(request.getContenido())
                .imagenUrl(request.getImagenUrl())
                .etiquetas(request.getEtiquetas())
                .publicadoPor(admin)
                .build();
        return NoticiaResponse.desde(noticiaRepository.save(noticia));
    }

    @Transactional
    public NoticiaResponse editar(Long id, NoticiaRequest request) {
        Noticia noticia = buscarEntidad(id);
        noticia.setTitulo(request.getTitulo());
        noticia.setResumen(request.getResumen());
        noticia.setContenido(request.getContenido());
        noticia.setImagenUrl(request.getImagenUrl());
        if (request.getEtiquetas() != null) noticia.setEtiquetas(request.getEtiquetas());
        return NoticiaResponse.desde(noticiaRepository.save(noticia));
    }

    @Transactional
    public void eliminar(Long id) {
        if (!noticiaRepository.existsById(id)) {
            throw new ResourceNotFoundException("Noticia no encontrada");
        }
        noticiaRepository.deleteById(id);
    }
}

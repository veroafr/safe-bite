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

import java.util.Collection;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class NoticiaService {

    private final NoticiaRepository noticiaRepository;
    private final IntoleranciaService intoleranciaService;

    public List<NoticiaResponse> listar(String etiqueta) {
        return listar(etiqueta, null);
    }

    /**
     * @param intolerancias si se indican, solo noticias relacionadas con ALGUNA de ellas
     */
    public List<NoticiaResponse> listar(String etiqueta, Collection<String> intolerancias) {
        return listar(etiqueta, intolerancias, null);
    }

    /**
     * @param pais UY o BR: solo las noticias importadas de ese país y las
     *             cargadas por el administrador (que no tienen país)
     */
    public List<NoticiaResponse> listar(String etiqueta, Collection<String> intolerancias, String pais) {
        List<Noticia> noticias = noticiaRepository.findAll();
        Set<String> filtro = intoleranciaService.normalizar(intolerancias);
        return noticias.stream()
                .filter(n -> !Boolean.TRUE.equals(n.getOculta()))
                .filter(n -> pais == null || pais.isBlank() || n.getPais() == null || n.getPais().equalsIgnoreCase(pais))
                .filter(n -> etiqueta == null || etiqueta.isBlank()
                        || n.getEtiquetas().stream().anyMatch(e -> e.equalsIgnoreCase(etiqueta)))
                .filter(n -> filtro.isEmpty() || n.getIntolerancias().stream().anyMatch(filtro::contains))
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
                .etiquetas(request.getEtiquetas() != null ? request.getEtiquetas() : new HashSet<>())
                .intolerancias(intoleranciaService.normalizar(request.getIntolerancias()))
                .publicadoPor(admin)
                .origen("MANUAL")
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
        if (request.getIntolerancias() != null) noticia.setIntolerancias(intoleranciaService.normalizar(request.getIntolerancias()));
        return NoticiaResponse.desde(noticiaRepository.save(noticia));
    }

    @Transactional
    public void eliminar(Long id) {
        Noticia noticia = buscarEntidad(id);
        if (noticia.esImportada()) {
            // Se oculta en lugar de borrarla, para que no se vuelva a importar.
            noticia.setOculta(true);
            noticiaRepository.save(noticia);
        } else {
            noticiaRepository.delete(noticia);
        }
    }
}

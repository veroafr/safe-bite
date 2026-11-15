package com.safebite.backend.service;

import com.safebite.backend.dto.request.RecetaRequest;
import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Receta;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.RecetaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RecetaService {

    private final RecetaRepository recetaRepository;
    private final IntoleranciaService intoleranciaService;

    /**
     * @param filtro intolerancias elegidas: solo se devuelven recetas libres de TODAS ellas
     *               (campo libreDe; tambien se aceptan las viejas etiquetas "Sin Gluten", etc.).
     */
    public List<RecetaResponse> listar(Boolean esTip, Collection<String> filtro) {
        List<Receta> recetas = esTip != null ? recetaRepository.findByEsTip(esTip) : recetaRepository.findAll();
        Set<String> codigos = intoleranciaService.normalizar(filtro);

        return recetas.stream()
                .filter(r -> codigos.isEmpty() || libreDe(r).containsAll(codigos))
                .map(RecetaResponse::desde)
                .toList();
    }

    /** libreDe + lo que se deduce de etiquetas viejas tipo "Sin Gluten" / "Sin Lactosa". */
    private Set<String> libreDe(Receta receta) {
        Set<String> r = new HashSet<>(receta.getLibreDe());
        for (String etiqueta : receta.getEtiquetas()) {
            String e = etiqueta == null ? "" : etiqueta.trim().toLowerCase();
            if (e.equals("sin gluten") || e.equals("sin tacc")) r.addAll(TipoIntolerancia.LEGADO.get("GLUTEN"));
            if (e.equals("sin lactosa")) r.addAll(TipoIntolerancia.LEGADO.get("LACTOSA"));
            if (e.equals("sin frutos secos")) r.addAll(TipoIntolerancia.LEGADO.get("FRUTOS_SECOS"));
            if (e.equals("sin mariscos")) r.addAll(TipoIntolerancia.LEGADO.get("MARISCOS"));
        }
        return r;
    }

    public RecetaResponse obtener(Long id) {
        return RecetaResponse.desde(buscarEntidad(id));
    }

    public Receta buscarEntidad(Long id) {
        return recetaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Receta no encontrada"));
    }

    @Transactional
    public RecetaResponse crear(RecetaRequest request, Usuario admin) {
        Receta receta = Receta.builder()
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .tiempoPreparacionMinutos(request.getTiempoPreparacionMinutos())
                .dificultad(request.getDificultad())
                .imagenUrl(request.getImagenUrl())
                .esTip(request.isEsTip())
                .etiquetas(request.getEtiquetas() != null ? request.getEtiquetas() : new HashSet<>())
                .libreDe(intoleranciaService.normalizar(request.getLibreDe()))
                .ingredientes(request.getIngredientes())
                .pasos(request.getPasos())
                .publicadoPor(admin)
                .build();
        return RecetaResponse.desde(recetaRepository.save(receta));
    }

    @Transactional
    public RecetaResponse editar(Long id, RecetaRequest request) {
        Receta receta = buscarEntidad(id);
        receta.setTitulo(request.getTitulo());
        receta.setDescripcion(request.getDescripcion());
        receta.setTiempoPreparacionMinutos(request.getTiempoPreparacionMinutos());
        receta.setDificultad(request.getDificultad());
        receta.setImagenUrl(request.getImagenUrl());
        receta.setEsTip(request.isEsTip());
        if (request.getEtiquetas() != null) receta.setEtiquetas(request.getEtiquetas());
        if (request.getLibreDe() != null) receta.setLibreDe(intoleranciaService.normalizar(request.getLibreDe()));
        if (request.getIngredientes() != null) receta.setIngredientes(request.getIngredientes());
        if (request.getPasos() != null) receta.setPasos(request.getPasos());
        return RecetaResponse.desde(recetaRepository.save(receta));
    }

    @Transactional
    public void eliminar(Long id) {
        if (!recetaRepository.existsById(id)) {
            throw new ResourceNotFoundException("Receta no encontrada");
        }
        recetaRepository.deleteById(id);
    }
}

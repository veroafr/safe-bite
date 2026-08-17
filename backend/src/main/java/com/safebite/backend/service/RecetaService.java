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

import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RecetaService {

    private final RecetaRepository recetaRepository;

    public List<RecetaResponse> listar(Boolean esTip, TipoIntolerancia excluirIntolerancia, Set<TipoIntolerancia> intoleranciasUsuario) {
        List<Receta> recetas = esTip != null ? recetaRepository.findByEsTip(esTip) : recetaRepository.findAll();

        Set<TipoIntolerancia> filtro = excluirIntolerancia != null ? Set.of(excluirIntolerancia) : intoleranciasUsuario;

        return recetas.stream()
                .filter(r -> filtro == null || filtro.isEmpty() || cumpleFiltro(r, filtro))
                .map(RecetaResponse::desde)
                .toList();
    }

    private boolean cumpleFiltro(Receta receta, Set<TipoIntolerancia> intolerancias) {
        // Una receta cumple el filtro si sus etiquetas indican que es apta
        // (por convencion se etiquetan como "Sin Gluten", "Sin Lactosa", etc.)
        for (TipoIntolerancia intolerancia : intolerancias) {
            String etiquetaEsperada = etiquetaPara(intolerancia);
            boolean apta = receta.getEtiquetas().stream()
                    .anyMatch(e -> e.equalsIgnoreCase(etiquetaEsperada));
            if (!apta) return false;
        }
        return true;
    }

    private String etiquetaPara(TipoIntolerancia intolerancia) {
        return switch (intolerancia) {
            case GLUTEN -> "Sin Gluten";
            case LACTOSA -> "Sin Lactosa";
            case FRUTOS_SECOS -> "Sin Frutos Secos";
            case MARISCOS -> "Sin Mariscos";
        };
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
                .etiquetas(request.getEtiquetas())
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

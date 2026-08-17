package com.safebite.backend.service;

import com.safebite.backend.dto.request.ComentarioRequest;
import com.safebite.backend.dto.request.EvaluacionRequest;
import com.safebite.backend.dto.request.RestauranteRequest;
import com.safebite.backend.dto.response.ComentarioResponse;
import com.safebite.backend.dto.response.EvaluacionResponse;
import com.safebite.backend.dto.response.RestauranteResponse;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.*;
import com.safebite.backend.repository.ComentarioRepository;
import com.safebite.backend.repository.EvaluacionRepository;
import com.safebite.backend.repository.RestauranteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class RestauranteService {

    private final RestauranteRepository restauranteRepository;
    private final ComentarioRepository comentarioRepository;
    private final EvaluacionRepository evaluacionRepository;

    public List<RestauranteResponse> buscar(String nombre, String tipoCocina, TipoIntolerancia intolerancia) {
        Specification<Restaurante> spec = Specification.where(
                (root, query, cb) -> cb.equal(root.get("activo"), true));

        if (nombre != null && !nombre.isBlank()) {
            String like = "%" + nombre.toLowerCase() + "%";
            spec = spec.and((root, query, cb) -> cb.like(cb.lower(root.get("nombre")), like));
        }
        if (tipoCocina != null && !tipoCocina.isBlank()) {
            spec = spec.and((root, query, cb) -> {
                query.distinct(true);
                return cb.isMember(tipoCocina, root.get("tiposCocina"));
            });
        }
        if (intolerancia != null) {
            spec = spec.and((root, query, cb) -> {
                query.distinct(true);
                return cb.isMember(intolerancia, root.get("opcionesAptasPara"));
            });
        }

        return restauranteRepository.findAll(spec).stream().map(RestauranteResponse::desde).toList();
    }

    public RestauranteResponse obtener(Long id) {
        return RestauranteResponse.desde(buscarEntidad(id));
    }

    public Restaurante buscarEntidad(Long id) {
        return restauranteRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Restaurante no encontrado"));
    }

    @Transactional
    public RestauranteResponse crear(RestauranteRequest request, Usuario admin) {
        Restaurante restaurante = Restaurante.builder()
                .nombre(request.getNombre())
                .descripcion(request.getDescripcion())
                .direccion(request.getDireccion())
                .latitud(request.getLatitud())
                .longitud(request.getLongitud())
                .imagenUrl(request.getImagenUrl())
                .tiposCocina(request.getTiposCocina())
                .opcionesAptasPara(request.getOpcionesAptasPara())
                .creadoPor(admin)
                .build();
        return RestauranteResponse.desde(restauranteRepository.save(restaurante));
    }

    @Transactional
    public RestauranteResponse editar(Long id, RestauranteRequest request) {
        Restaurante restaurante = buscarEntidad(id);
        restaurante.setNombre(request.getNombre());
        restaurante.setDescripcion(request.getDescripcion());
        restaurante.setDireccion(request.getDireccion());
        restaurante.setLatitud(request.getLatitud());
        restaurante.setLongitud(request.getLongitud());
        restaurante.setImagenUrl(request.getImagenUrl());
        if (request.getTiposCocina() != null) restaurante.setTiposCocina(request.getTiposCocina());
        if (request.getOpcionesAptasPara() != null) restaurante.setOpcionesAptasPara(request.getOpcionesAptasPara());
        return RestauranteResponse.desde(restauranteRepository.save(restaurante));
    }

    @Transactional
    public void eliminar(Long id) {
        Restaurante restaurante = buscarEntidad(id);
        restaurante.setActivo(false);
        restauranteRepository.save(restaurante);
    }

    // ---- Comentarios ----

    @Transactional
    public ComentarioResponse comentar(Long restauranteId, Usuario usuario, ComentarioRequest request) {
        Restaurante restaurante = buscarEntidad(restauranteId);
        Comentario comentario = Comentario.builder()
                .restaurante(restaurante)
                .usuario(usuario)
                .texto(request.getTexto())
                .build();
        return ComentarioResponse.desde(comentarioRepository.save(comentario));
    }

    public List<ComentarioResponse> listarComentarios(Long restauranteId) {
        return comentarioRepository.findByRestauranteIdOrderByFechaDesc(restauranteId)
                .stream().map(ComentarioResponse::desde).toList();
    }

    // ---- Evaluaciones ----

    @Transactional
    public EvaluacionResponse evaluar(Long restauranteId, Usuario usuario, EvaluacionRequest request) {
        Restaurante restaurante = buscarEntidad(restauranteId);

        Evaluacion evaluacion = evaluacionRepository.findByRestauranteIdAndUsuarioId(restauranteId, usuario.getId())
                .orElse(Evaluacion.builder().restaurante(restaurante).usuario(usuario).build());

        evaluacion.setPuntuacion(request.getPuntuacion());
        evaluacion.setComentario(request.getComentario());
        evaluacion.setFecha(java.time.LocalDateTime.now());
        evaluacion = evaluacionRepository.save(evaluacion);

        Double promedio = evaluacionRepository.promedioPorRestaurante(restauranteId);
        restaurante.setRatingPromedio(promedio != null ? Math.round(promedio * 10.0) / 10.0 : 0.0);
        restauranteRepository.save(restaurante);

        return EvaluacionResponse.desde(evaluacion);
    }

    public List<EvaluacionResponse> listarEvaluaciones(Long restauranteId) {
        return evaluacionRepository.findByRestauranteIdOrderByFechaDesc(restauranteId)
                .stream().map(EvaluacionResponse::desde).toList();
    }
}

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
import java.util.Set;

@Service
@RequiredArgsConstructor
public class RestauranteService {

    private final RestauranteRepository restauranteRepository;
    private final ComentarioRepository comentarioRepository;
    private final EvaluacionRepository evaluacionRepository;
    private final IntoleranciaService intoleranciaService;

    /**
     * @param intolerancias el restaurante tiene que tener opciones aptas para TODAS las indicadas
     */
    public List<RestauranteResponse> buscar(String nombre, String tipoCocina, java.util.Collection<String> intolerancias) {
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
        Set<String> filtro = intoleranciaService.normalizar(intolerancias);

        return restauranteRepository.findAll(spec).stream()
                .filter(r -> r.getOpcionesAptasPara().containsAll(filtro))
                .map(RestauranteResponse::resumen).toList();
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
                .opcionesAptasPara(intoleranciaService.normalizar(request.getOpcionesAptasPara()))
                .creadoPor(admin)
                .build();
        aplicarFotos(restaurante, request);
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
        if (request.getOpcionesAptasPara() != null) restaurante.setOpcionesAptasPara(intoleranciaService.normalizar(request.getOpcionesAptasPara()));
        aplicarFotos(restaurante, request);
        return RestauranteResponse.desde(restauranteRepository.save(restaurante));
    }

    /** null = no se toca la foto; "" = se quita; otra cosa = foto nueva, ajustada al tamaño final. */
    private void aplicarFotos(Restaurante restaurante, RestauranteRequest request) {
        String mini = request.getImagenMiniatura();
        if (mini != null) {
            restaurante.setImagenMiniatura(mini.isBlank() ? null
                    : ImagenRestauranteUtil.preparar(mini, ImagenRestauranteUtil.MINIATURA_LADO, ImagenRestauranteUtil.MINIATURA_LADO));
        }
        String banner = request.getImagenBanner();
        if (banner != null) {
            restaurante.setImagenBanner(banner.isBlank() ? null
                    : ImagenRestauranteUtil.preparar(banner, ImagenRestauranteUtil.BANNER_ANCHO, ImagenRestauranteUtil.BANNER_ALTO));
        }
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

    /**
     * Guarda la reseña (estrellas + comentario) como PENDIENTE: se publica
     * recién cuando el administrador la aprueba, para evitar reseñas falsas.
     * Si el usuario ya tenía una, se reemplaza y vuelve a revisión.
     */
    @Transactional
    public EvaluacionResponse evaluar(Long restauranteId, Usuario usuario, EvaluacionRequest request) {
        Restaurante restaurante = buscarEntidad(restauranteId);

        Evaluacion evaluacion = evaluacionRepository.findByRestauranteIdAndUsuarioId(restauranteId, usuario.getId())
                .orElse(Evaluacion.builder().restaurante(restaurante).usuario(usuario).build());

        evaluacion.setPuntuacion(request.getPuntuacion());
        evaluacion.setComentario(request.getComentario().trim());
        evaluacion.setFecha(java.time.LocalDateTime.now());
        evaluacion.setEstado(Evaluacion.PENDIENTE);
        evaluacion.setMotivoRechazo(null);
        evaluacion.setFechaRevision(null);
        evaluacion = evaluacionRepository.save(evaluacion);

        // Si reemplazó una reseña ya publicada, el promedio deja de contarla.
        recalcularPromedio(restaurante);
        return EvaluacionResponse.desde(evaluacion);
    }

    /** Reseñas publicadas del restaurante. */
    public List<EvaluacionResponse> listarEvaluaciones(Long restauranteId) {
        return evaluacionRepository.findByRestauranteIdOrderByFechaDesc(restauranteId)
                .stream().filter(Evaluacion::estaPublicada).map(EvaluacionResponse::desde).toList();
    }

    /** La reseña del usuario para ese restaurante (con su estado), si tiene. */
    public java.util.Optional<EvaluacionResponse> miEvaluacion(Long restauranteId, Usuario usuario) {
        return evaluacionRepository.findByRestauranteIdAndUsuarioId(restauranteId, usuario.getId())
                .map(EvaluacionResponse::desde);
    }

    // ---- Moderación (administrador) ----

    public List<EvaluacionResponse> listarPorEstado(String estado) {
        String e = estado == null || estado.isBlank() ? Evaluacion.PENDIENTE : estado.toUpperCase();
        return evaluacionRepository.findByEstadoOrderByFechaAsc(e).stream().map(EvaluacionResponse::desde).toList();
    }

    @Transactional
    public EvaluacionResponse moderar(Long evaluacionId, boolean aprobar, String motivo) {
        Evaluacion evaluacion = evaluacionRepository.findById(evaluacionId)
                .orElseThrow(() -> new ResourceNotFoundException("Reseña no encontrada"));
        evaluacion.setEstado(aprobar ? Evaluacion.APROBADA : Evaluacion.RECHAZADA);
        evaluacion.setMotivoRechazo(aprobar ? null : (motivo == null || motivo.isBlank() ? null : motivo.trim()));
        evaluacion.setFechaRevision(java.time.LocalDateTime.now());
        evaluacion = evaluacionRepository.save(evaluacion);
        recalcularPromedio(evaluacion.getRestaurante());
        return EvaluacionResponse.desde(evaluacion);
    }

    private void recalcularPromedio(Restaurante restaurante) {
        Double promedio = evaluacionRepository.promedioPorRestaurante(restaurante.getId());
        restaurante.setRatingPromedio(promedio != null ? Math.round(promedio * 10.0) / 10.0 : 0.0);
        restauranteRepository.save(restaurante);
    }
}

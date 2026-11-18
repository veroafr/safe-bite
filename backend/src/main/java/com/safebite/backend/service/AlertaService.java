package com.safebite.backend.service;

import com.safebite.backend.dto.request.AlertaRequest;
import com.safebite.backend.dto.request.RevisarAlertaRequest;
import com.safebite.backend.dto.response.AlertaResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Alerta;
import com.safebite.backend.model.EstadoAlerta;
import com.safebite.backend.model.Producto;
import com.safebite.backend.model.Restaurante;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.AlertaRepository;
import com.safebite.backend.repository.ProductoRepository;
import com.safebite.backend.repository.RestauranteRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AlertaService {

    private final AlertaRepository alertaRepository;
    private final RestauranteRepository restauranteRepository;
    private final ProductoRepository productoRepository;

    @Transactional
    public AlertaResponse crear(AlertaRequest request, Usuario usuario) {
        Restaurante restaurante = null;
        Producto producto = null;

        if (request.getRestauranteId() != null) {
            restaurante = restauranteRepository.findById(request.getRestauranteId())
                    .orElseThrow(() -> new ResourceNotFoundException("Restaurante no encontrado"));
        }
        if (request.getProductoId() != null) {
            producto = productoRepository.findById(request.getProductoId())
                    .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado"));
        }
        if (restaurante == null && producto == null) {
            throw new BadRequestException("La alerta debe estar asociada a un restaurante o a un producto");
        }

        String telefono = request.getTelefonoContacto() == null ? null : request.getTelefonoContacto().trim();
        if (telefono != null && telefono.isEmpty()) telefono = null;
        if (telefono != null) {
            long digitos = telefono.chars().filter(Character::isDigit).count();
            if (digitos < 8 || digitos > 15 || !telefono.matches("[0-9+()\\s.-]+")) {
                throw new BadRequestException("El teléfono de contacto no es válido");
            }
        }
        if (restaurante != null && telefono == null) {
            throw new BadRequestException("Indicá un teléfono de contacto para poder comunicarnos con vos");
        }

        java.util.List<String> pruebas = new java.util.ArrayList<>();
        if (request.getPruebas() != null) {
            if (request.getPruebas().size() > 3) throw new BadRequestException("Podés adjuntar hasta 3 imágenes");
            for (String img : request.getPruebas()) {
                if (img == null || img.isBlank()) continue;
                if (img.length() > 12_000_000) throw new BadRequestException("Una de las imágenes es demasiado grande");
                pruebas.add(ImagenRestauranteUtil.ajustar(img, 1280));
            }
        }

        Alerta alerta = Alerta.builder()
                .usuario(usuario)
                .tipo(request.getTipo())
                .restaurante(restaurante)
                .producto(producto)
                .descripcion(request.getDescripcion().trim())
                .telefonoContacto(telefono)
                .pruebas(pruebas)
                .estado(EstadoAlerta.PENDIENTE)
                .build();

        return AlertaResponse.desde(alertaRepository.save(alerta));
    }

    public List<AlertaResponse> listarDeUsuario(Long usuarioId) {
        return alertaRepository.findByUsuarioIdOrderByFechaDesc(usuarioId)
                .stream().map(AlertaResponse::desde).toList();
    }

    public List<AlertaResponse> listarPorEstado(EstadoAlerta estado) {
        List<Alerta> alertas = estado != null
                ? alertaRepository.findByEstadoOrderByFechaDesc(estado)
                : alertaRepository.findAll();
        return alertas.stream().map(AlertaResponse::desde).toList();
    }

    @Transactional
    public AlertaResponse revisar(Long id, RevisarAlertaRequest request, Usuario admin) {
        Alerta alerta = alertaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Alerta no encontrada"));

        if (request.getEstado() == EstadoAlerta.PENDIENTE) {
            throw new BadRequestException("El estado de revision debe ser ACEPTADA o DENEGADA");
        }

        alerta.setEstado(request.getEstado());
        alerta.setRevisadoPor(admin);
        alerta.setFechaRevision(LocalDateTime.now());

        return AlertaResponse.desde(alertaRepository.save(alerta));
    }
}

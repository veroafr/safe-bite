package com.safebite.backend.service;

import com.safebite.backend.dto.request.RecuperarPasswordRequest;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.SolicitudRecuperacion;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.SolicitudRecuperacionRepository;
import com.safebite.backend.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Recuperación de contraseña asistida por el administrador (sin emails automáticos):
 *  1) la persona escribe su email (y opcionalmente un teléfono) en "¿Olvidaste tu contraseña?";
 *  2) el pedido aparece en el panel de administración;
 *  3) el administrador asigna una contraseña temporal y se la comunica;
 *  4) al entrar, la app le pide a la persona que la cambie.
 */
@Service
@RequiredArgsConstructor
public class RecuperacionService {

    private final SolicitudRecuperacionRepository repository;
    private final UsuarioRepository usuarioRepository;
    private final UsuarioService usuarioService;

    /** Siempre responde igual, exista o no la cuenta, para no revelar qué emails están registrados. */
    @Transactional
    public void solicitar(RecuperarPasswordRequest req) {
        String email = req.getEmail().trim().toLowerCase();
        Optional<Usuario> usuario = usuarioRepository.findByEmail(email);
        // Un segundo pedido del mismo email actualiza el pendiente en lugar de duplicarlo.
        SolicitudRecuperacion s = repository.findFirstByEmailIgnoreCaseAndEstado(email, SolicitudRecuperacion.PENDIENTE)
                .orElseGet(() -> SolicitudRecuperacion.builder().email(email).build());
        s.setUsuario(usuario.orElse(null));
        if (req.getTelefono() != null && !req.getTelefono().isBlank()) s.setTelefono(req.getTelefono().trim());
        if (req.getMensaje() != null && !req.getMensaje().isBlank()) s.setMensaje(req.getMensaje().trim());
        s.setFecha(LocalDateTime.now());
        repository.save(s);
    }

    public List<Map<String, Object>> listar(String estado) {
        List<SolicitudRecuperacion> lista = estado == null || estado.isBlank() || estado.equalsIgnoreCase("TODAS")
                ? repository.findAllByOrderByFechaDesc()
                : repository.findByEstadoOrderByFechaDesc(estado.toUpperCase());
        return lista.stream().map(this::aMapa).toList();
    }

    public long pendientes() {
        return repository.countByEstado(SolicitudRecuperacion.PENDIENTE);
    }

    /** Asigna una contraseña temporal a la cuenta y marca el pedido como resuelto. */
    @Transactional
    public Map<String, Object> resolver(Long id, String nuevaPassword, String nota, Usuario admin) {
        SolicitudRecuperacion s = buscar(id);
        Usuario usuario = s.getUsuario() != null ? s.getUsuario()
                : usuarioRepository.findByEmail(s.getEmail()).orElse(null);
        if (usuario == null) {
            throw new BadRequestException("No hay ninguna cuenta con ese email. Buscá a la persona en Usuarios "
                    + "(puede haber escrito mal el email) o descartá el pedido.");
        }
        usuarioService.asignarPassword(usuario.getId(), nuevaPassword, true);
        s.setUsuario(usuario);
        s.setEstado(SolicitudRecuperacion.RESUELTA);
        s.setFechaResolucion(LocalDateTime.now());
        s.setResueltaPor(admin);
        s.setNota(nota == null || nota.isBlank() ? null : nota.trim());
        return aMapa(repository.save(s));
    }

    @Transactional
    public Map<String, Object> descartar(Long id, String nota, Usuario admin) {
        SolicitudRecuperacion s = buscar(id);
        s.setEstado(SolicitudRecuperacion.DESCARTADA);
        s.setFechaResolucion(LocalDateTime.now());
        s.setResueltaPor(admin);
        s.setNota(nota == null || nota.isBlank() ? null : nota.trim());
        return aMapa(repository.save(s));
    }

    private SolicitudRecuperacion buscar(Long id) {
        return repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Pedido no encontrado"));
    }

    private Map<String, Object> aMapa(SolicitudRecuperacion s) {
        Usuario u = s.getUsuario();
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", s.getId());
        m.put("email", s.getEmail());
        m.put("telefono", s.getTelefono());
        m.put("mensaje", s.getMensaje());
        m.put("estado", s.getEstado());
        m.put("fecha", s.getFecha());
        m.put("fechaResolucion", s.getFechaResolucion());
        m.put("nota", s.getNota());
        m.put("cuentaEncontrada", u != null);
        if (u != null) {
            m.put("usuarioId", u.getId());
            m.put("usuarioNombre", u.getNombre());
            m.put("usuarioTelefono", u.getTelefono());
            m.put("usuarioActivo", u.isActivo());
        }
        if (s.getResueltaPor() != null) m.put("resueltaPor", s.getResueltaPor().getNombre());
        return m;
    }
}

package com.safebite.backend.service;

import com.safebite.backend.dto.request.ActualizarPerfilRequest;
import com.safebite.backend.dto.request.CambiarPasswordRequest;
import com.safebite.backend.dto.request.PreferenciasRequest;
import com.safebite.backend.dto.response.UsuarioResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Rol;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final IntoleranciaService intoleranciaService;

    public Usuario obtenerPorEmail(String email) {
        return usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
    }

    @Transactional
    public UsuarioResponse actualizarPerfil(Usuario usuario, ActualizarPerfilRequest request) {
        if (request.getNombre() != null) usuario.setNombre(request.getNombre());
        if (request.getCiudad() != null) usuario.setCiudad(request.getCiudad());
        if (request.getPais() != null) usuario.setPais(request.getPais());
        if (request.getFotoPerfilUrl() != null) usuario.setFotoPerfilUrl(request.getFotoPerfilUrl());
        if (request.getIdioma() != null) usuario.setIdioma(request.getIdioma());
        if (request.getTelefono() != null) usuario.setTelefono(request.getTelefono().isBlank() ? null : request.getTelefono().trim());
        if (request.getFotoBase64() != null) {
            usuario.setFotoPerfilDatos(request.getFotoBase64().isBlank()
                    ? null : ImagenRestauranteUtil.preparar(request.getFotoBase64(), 400, 400));
            if (request.getFotoBase64().isBlank()) usuario.setFotoPerfilUrl(null);
        }
        if (request.getEmail() != null && !request.getEmail().trim().equalsIgnoreCase(usuario.getEmail())) {
            String email = request.getEmail().trim().toLowerCase();
            if (usuarioRepository.existsByEmail(email)) {
                throw new BadRequestException("Ese email ya esta en uso");
            }
            usuario.setEmail(email);
        }
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    @Transactional
    public void cambiarPassword(Usuario usuario, CambiarPasswordRequest request) {
        if (!passwordEncoder.matches(request.getPasswordActual(), usuario.getPassword())) {
            throw new BadRequestException("La contraseña actual es incorrecta");
        }
        usuario.setPassword(passwordEncoder.encode(request.getPasswordNueva()));
        usuario.setDebeCambiarPassword(false);
        usuarioRepository.save(usuario);
    }

    @Transactional
    public UsuarioResponse actualizarPreferencias(Usuario usuario, PreferenciasRequest request) {
        if (request.getIntolerancias() != null) usuario.setIntolerancias(intoleranciaService.normalizar(request.getIntolerancias()));
        if (request.getBuscaAlimentacionSaludable() != null) usuario.setBuscaAlimentacionSaludable(request.getBuscaAlimentacionSaludable());
        if (request.getNivelAlerta() != null) usuario.setNivelAlerta(request.getNivelAlerta());
        if (request.getTiposCocinaPreferidos() != null) usuario.setTiposCocinaPreferidos(request.getTiposCocinaPreferidos());
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    // ---- Administracion de usuarios ----

    public List<UsuarioResponse> listarTodos() {
        return usuarioRepository.findAll().stream().map(UsuarioResponse::desde).toList();
    }

    @Transactional
    public UsuarioResponse crearUsuarioAdmin(ActualizarPerfilRequest datos, String password, Rol rol) {
        if (usuarioRepository.existsByEmail(datos.getEmail())) {
            throw new BadRequestException("Ya existe un usuario con ese email");
        }
        Usuario usuario = Usuario.builder()
                .nombre(datos.getNombre())
                .email(datos.getEmail())
                .password(passwordEncoder.encode(password))
                .ciudad(datos.getCiudad())
                .pais(datos.getPais())
                .rol(rol != null ? rol : Rol.USUARIO)
                .build();
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    /** El administrador edita todo el perfil (para ayudar a recuperar una cuenta). */
    @Transactional
    public UsuarioResponse editarUsuarioAdmin(Long id, ActualizarPerfilRequest request, Usuario admin) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        if (request.getNombre() != null && request.getNombre().isBlank()) {
            throw new BadRequestException("El nombre no puede quedar vacío");
        }
        if (request.getIntolerancias() != null) usuario.setIntolerancias(intoleranciaService.normalizar(request.getIntolerancias()));
        if (request.getBuscaAlimentacionSaludable() != null) usuario.setBuscaAlimentacionSaludable(request.getBuscaAlimentacionSaludable());
        if (request.getNivelAlerta() != null) usuario.setNivelAlerta(request.getNivelAlerta());
        if (request.getTiposCocinaPreferidos() != null) usuario.setTiposCocinaPreferidos(new java.util.HashSet<>(request.getTiposCocinaPreferidos()));
        boolean esUnoMismo = admin != null && admin.getId().equals(usuario.getId());
        if (request.getActivo() != null) {
            if (esUnoMismo && !request.getActivo()) throw new BadRequestException("No podés desactivar tu propia cuenta");
            usuario.setActivo(request.getActivo());
        }
        if (request.getRol() != null) {
            if (esUnoMismo && request.getRol() != Rol.ADMINISTRADOR) throw new BadRequestException("No podés quitarte el rol de administrador");
            usuario.setRol(request.getRol());
        }
        return actualizarPerfil(usuario, request);
    }

    /**
     * Contraseña asignada por el administrador. Con [temporal] = true, la app
     * le pide a la persona que la cambie al entrar.
     */
    @Transactional
    public UsuarioResponse asignarPassword(Long id, String nueva, boolean temporal) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        validarPasswordNueva(nueva);
        usuario.setPassword(passwordEncoder.encode(nueva));
        usuario.setDebeCambiarPassword(temporal);
        usuario.setCodigoRecuperacionHash(null);
        usuario.setCodigoRecuperacionExpira(null);
        usuario.setIntentosRecuperacion(null);
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    public static void validarPasswordNueva(String p) {
        if (p == null || !p.matches(com.safebite.backend.config.Validaciones.PASSWORD)) {
            throw new BadRequestException(com.safebite.backend.config.Validaciones.PASSWORD_MENSAJE);
        }
    }

    public UsuarioResponse obtenerAdmin(Long id) {
        return UsuarioResponse.desde(usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado")));
    }

    @Transactional
    public void eliminarUsuario(Long id) {
        if (!usuarioRepository.existsById(id)) {
            throw new ResourceNotFoundException("Usuario no encontrado");
        }
        usuarioRepository.deleteById(id);
    }
}

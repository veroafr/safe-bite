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
        if (request.getEmail() != null && !request.getEmail().equals(usuario.getEmail())) {
            if (usuarioRepository.existsByEmail(request.getEmail())) {
                throw new BadRequestException("Ese email ya esta en uso");
            }
            usuario.setEmail(request.getEmail());
        }
        return UsuarioResponse.desde(usuarioRepository.save(usuario));
    }

    @Transactional
    public void cambiarPassword(Usuario usuario, CambiarPasswordRequest request) {
        if (!passwordEncoder.matches(request.getPasswordActual(), usuario.getPassword())) {
            throw new BadRequestException("La contraseña actual es incorrecta");
        }
        usuario.setPassword(passwordEncoder.encode(request.getPasswordNueva()));
        usuarioRepository.save(usuario);
    }

    @Transactional
    public UsuarioResponse actualizarPreferencias(Usuario usuario, PreferenciasRequest request) {
        if (request.getIntolerancias() != null) usuario.setIntolerancias(request.getIntolerancias());
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

    @Transactional
    public UsuarioResponse editarUsuarioAdmin(Long id, ActualizarPerfilRequest request) {
        Usuario usuario = usuarioRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Usuario no encontrado"));
        return actualizarPerfil(usuario, request);
    }

    @Transactional
    public void eliminarUsuario(Long id) {
        if (!usuarioRepository.existsById(id)) {
            throw new ResourceNotFoundException("Usuario no encontrado");
        }
        usuarioRepository.deleteById(id);
    }
}

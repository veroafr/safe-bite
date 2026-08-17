package com.safebite.backend.service;

import com.safebite.backend.config.JwtUtil;
import com.safebite.backend.dto.request.LoginRequest;
import com.safebite.backend.dto.request.RecuperarPasswordRequest;
import com.safebite.backend.dto.request.RegistroRequest;
import com.safebite.backend.dto.response.AuthResponse;
import com.safebite.backend.dto.response.UsuarioResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.model.Rol;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;

    @Transactional
    public AuthResponse registrar(RegistroRequest request) {
        if (usuarioRepository.existsByEmail(request.getEmail())) {
            throw new BadRequestException("Ya existe una cuenta registrada con ese email");
        }

        Usuario usuario = Usuario.builder()
                .nombre(request.getNombre())
                .email(request.getEmail())
                .password(passwordEncoder.encode(request.getPassword()))
                .idioma(request.getIdioma() != null ? request.getIdioma() : "es")
                .ciudad(request.getCiudad())
                .pais(request.getPais())
                .rol(Rol.USUARIO)
                .build();

        usuario = usuarioRepository.save(usuario);

        String token = jwtUtil.generarToken(usuario, Map.of("rol", usuario.getRol().name()));

        return AuthResponse.builder()
                .token(token)
                .usuario(UsuarioResponse.desde(usuario))
                .build();
    }

    public AuthResponse login(LoginRequest request) {
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.getEmail(), request.getPassword()));

        Usuario usuario = usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("Credenciales invalidas"));

        String token = jwtUtil.generarToken(usuario, Map.of("rol", usuario.getRol().name()));

        return AuthResponse.builder()
                .token(token)
                .usuario(UsuarioResponse.desde(usuario))
                .build();
    }

    public void recuperarPassword(RecuperarPasswordRequest request) {
        // Simulacion del flujo de recuperacion de contraseña: en produccion aqui
        // se generaria un token de un solo uso y se enviaria por email/SMS.
        usuarioRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("No existe una cuenta con ese email"));
    }
}

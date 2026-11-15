package com.safebite.backend.service;

import com.safebite.backend.config.JwtUtil;
import com.safebite.backend.dto.request.LoginRequest;
import com.safebite.backend.dto.request.RecuperarPasswordRequest;
import com.safebite.backend.dto.request.RegistroRequest;
import com.safebite.backend.dto.request.RestablecerPasswordRequest;
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

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UsuarioRepository usuarioRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuthenticationManager authenticationManager;
    private final IntoleranciaService intoleranciaService;
    private final EmailService emailService;

    private static final int MINUTOS_VALIDEZ_CODIGO = 15;
    private static final int MAX_INTENTOS_CODIGO = 5;
    private static final SecureRandom RANDOM = new SecureRandom();

    @Transactional
    public AuthResponse registrar(RegistroRequest request) {
        String email = request.getEmail().trim().toLowerCase();
        if (usuarioRepository.existsByEmail(email)) {
            throw new BadRequestException("Ya existe una cuenta registrada con ese email");
        }
        Set<String> intolerancias = intoleranciaService.normalizar(request.getIntolerancias());
        boolean comerMejor = Boolean.TRUE.equals(request.getBuscaAlimentacionSaludable());
        if (intolerancias.isEmpty() && !comerMejor) {
            throw new BadRequestException("Elegí al menos una restricción alimentaria o la opción \"Busco alimentarme mejor\"");
        }

        Usuario usuario = Usuario.builder()
                .nombre(request.getNombre().trim())
                .email(email)
                .password(passwordEncoder.encode(request.getPassword()))
                .idioma(request.getIdioma() != null ? request.getIdioma() : "es")
                .ciudad(request.getCiudad())
                .pais(request.getPais())
                .intolerancias(new HashSet<>(intolerancias))
                .buscaAlimentacionSaludable(comerMejor)
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
        String email = emailExistente(request.getEmail());
        authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(email, request.getPassword()));

        Usuario usuario = usuarioRepository.findByEmail(email)
                .orElseThrow(() -> new BadRequestException("Credenciales invalidas"));

        String token = jwtUtil.generarToken(usuario, Map.of("rol", usuario.getRol().name()));

        return AuthResponse.builder()
                .token(token)
                .usuario(UsuarioResponse.desde(usuario))
                .build();
    }

    /**
     * Paso 1: genera un codigo de 6 digitos, guarda su hash con vencimiento y
     * lo envia por email. La respuesta es siempre la misma exista o no la
     * cuenta, para no revelar que emails estan registrados.
     */
    @Transactional
    public void recuperarPassword(RecuperarPasswordRequest request) {
        usuarioRepository.findByEmail(emailExistente(request.getEmail())).ifPresent(usuario -> {
            String codigo = String.format("%06d", RANDOM.nextInt(1_000_000));
            usuario.setCodigoRecuperacionHash(passwordEncoder.encode(codigo));
            usuario.setCodigoRecuperacionExpira(LocalDateTime.now().plusMinutes(MINUTOS_VALIDEZ_CODIGO));
            usuario.setIntentosRecuperacion(0);
            usuarioRepository.save(usuario);

            emailService.enviar(usuario.getEmail(), "Safe-Bite: código para restablecer tu contraseña",
                    "Hola " + usuario.getNombre() + ",\n\n"
                            + "Tu código para restablecer la contraseña es: " + codigo + "\n\n"
                            + "Vence en " + MINUTOS_VALIDEZ_CODIGO + " minutos. Si no lo pediste, ignorá este mensaje.\n\n"
                            + "Equipo Safe-Bite");
        });
    }

    /** Paso 2: valida el codigo y guarda la nueva contraseña. */
    @Transactional
    public void restablecerPassword(RestablecerPasswordRequest request) {
        String error = "El código es incorrecto o venció. Pedí uno nuevo.";
        Usuario usuario = usuarioRepository.findByEmail(emailExistente(request.getEmail()))
                .orElseThrow(() -> new BadRequestException(error));

        if (usuario.getCodigoRecuperacionHash() == null || usuario.getCodigoRecuperacionExpira() == null
                || usuario.getCodigoRecuperacionExpira().isBefore(LocalDateTime.now())) {
            throw new BadRequestException(error);
        }
        int intentos = usuario.getIntentosRecuperacion() == null ? 0 : usuario.getIntentosRecuperacion();
        if (intentos >= MAX_INTENTOS_CODIGO) {
            limpiarCodigo(usuario);
            usuarioRepository.save(usuario);
            throw new BadRequestException("Superaste la cantidad de intentos. Pedí un código nuevo.");
        }
        if (!passwordEncoder.matches(request.getCodigo(), usuario.getCodigoRecuperacionHash())) {
            usuario.setIntentosRecuperacion(intentos + 1);
            usuarioRepository.save(usuario);
            throw new BadRequestException(error);
        }

        usuario.setPassword(passwordEncoder.encode(request.getPasswordNueva()));
        limpiarCodigo(usuario);
        usuarioRepository.save(usuario);
    }

    private void limpiarCodigo(Usuario usuario) {
        usuario.setCodigoRecuperacionHash(null);
        usuario.setCodigoRecuperacionExpira(null);
        usuario.setIntentosRecuperacion(null);
    }

    /**
     * Los emails nuevos se guardan en minusculas. Para no dejar afuera cuentas
     * viejas guardadas con mayusculas, se prueba primero el email tal cual.
     */
    private String emailExistente(String email) {
        String limpio = email == null ? "" : email.trim();
        if (usuarioRepository.existsByEmail(limpio)) return limpio;
        return limpio.toLowerCase();
    }
}

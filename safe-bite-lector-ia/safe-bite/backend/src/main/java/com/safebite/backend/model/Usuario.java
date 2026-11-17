package com.safebite.backend.model;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Entity
@Table(name = "usuarios")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Usuario implements UserDetails {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nombre;

    @Column(nullable = false, unique = true)
    private String email;

    @JsonIgnore
    @Column(nullable = false)
    private String password;

    private String fotoPerfilUrl;

    private String ciudad;

    private String pais;

    @Builder.Default
    private String idioma = "es";

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Rol rol = Rol.USUARIO;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "usuario_intolerancias", joinColumns = @JoinColumn(name = "usuario_id"))
    @Column(name = "intolerancia")
    @Builder.Default
    private Set<String> intolerancias = new HashSet<>();

    /**
     * Opcion "Busco alimentarme mejor" del registro: el usuario no declara
     * (o no solo declara) una restriccion, sino que quiere comer mas sano.
     * Boolean (no boolean) para que la columna nueva admita filas viejas en null.
     */
    @Builder.Default
    private Boolean buscaAlimentacionSaludable = false;

    @Enumerated(EnumType.STRING)
    @Builder.Default
    private NivelAlerta nivelAlerta = NivelAlerta.ALTO;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "usuario_tipos_cocina", joinColumns = @JoinColumn(name = "usuario_id"))
    @Column(name = "tipo_cocina")
    @Builder.Default
    private Set<String> tiposCocinaPreferidos = new HashSet<>();

    @Builder.Default
    private boolean activo = true;

    @Builder.Default
    private LocalDateTime fechaRegistro = LocalDateTime.now();

    // ---- Recuperacion de contraseña ----

    /** Hash (BCrypt) del codigo de 6 digitos enviado por email. Nunca se guarda en claro. */
    @JsonIgnore
    private String codigoRecuperacionHash;

    @JsonIgnore
    private LocalDateTime codigoRecuperacionExpira;

    @JsonIgnore
    private Integer intentosRecuperacion;

    public boolean isBuscaAlimentacionSaludable() {
        return Boolean.TRUE.equals(buscaAlimentacionSaludable);
    }

    // ---- UserDetails ----

    @Override
    @JsonIgnore
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + rol.name()));
    }

    @Override
    @JsonIgnore
    public String getUsername() {
        return email;
    }

    @Override
    @JsonIgnore
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    @JsonIgnore
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    @JsonIgnore
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    @JsonIgnore
    public boolean isEnabled() {
        return activo;
    }
}

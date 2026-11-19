package com.safebite.backend.controller;

import com.safebite.backend.dto.request.ActualizarPerfilRequest;
import com.safebite.backend.dto.response.UsuarioResponse;
import com.safebite.backend.model.Rol;
import com.safebite.backend.service.UsuarioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/usuarios")
@RequiredArgsConstructor
public class AdminUsuarioController {

    private final UsuarioService usuarioService;

    @GetMapping
    public ResponseEntity<List<UsuarioResponse>> listar() {
        return ResponseEntity.ok(usuarioService.listarTodos());
    }

    @PostMapping
    public ResponseEntity<UsuarioResponse> crear(@RequestBody Map<String, Object> body) {
        ActualizarPerfilRequest datos = new ActualizarPerfilRequest();
        datos.setNombre((String) body.get("nombre"));
        datos.setEmail((String) body.get("email"));
        datos.setCiudad((String) body.get("ciudad"));
        datos.setPais((String) body.get("pais"));
        String password = (String) body.getOrDefault("password", "safebite123");
        Rol rol = body.get("rol") != null ? Rol.valueOf((String) body.get("rol")) : Rol.USUARIO;
        return ResponseEntity.status(HttpStatus.CREATED).body(usuarioService.crearUsuarioAdmin(datos, password, rol));
    }

    @GetMapping("/{id}")
    public ResponseEntity<UsuarioResponse> obtener(@PathVariable Long id) {
        return ResponseEntity.ok(usuarioService.obtenerAdmin(id));
    }

    /** Edita todo el perfil: nombre, email, ubicación, teléfono, foto, intolerancias, rol, activo... */
    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponse> editar(@PathVariable Long id,
                                                  @org.springframework.security.core.annotation.AuthenticationPrincipal com.safebite.backend.model.Usuario admin,
                                                  @jakarta.validation.Valid @RequestBody ActualizarPerfilRequest request) {
        return ResponseEntity.ok(usuarioService.editarUsuarioAdmin(id, request, admin));
    }

    /** Body: {"password": "Nueva#123", "temporal": true} */
    @PutMapping("/{id}/password")
    public ResponseEntity<UsuarioResponse> asignarPassword(@PathVariable Long id, @RequestBody Map<String, Object> body) {
        Object p = body.get("password");
        boolean temporal = !Boolean.FALSE.equals(body.get("temporal"));
        return ResponseEntity.ok(usuarioService.asignarPassword(id, p == null ? null : p.toString(), temporal));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        usuarioService.eliminarUsuario(id);
        return ResponseEntity.noContent().build();
    }
}

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

    @PutMapping("/{id}")
    public ResponseEntity<UsuarioResponse> editar(@PathVariable Long id, @RequestBody ActualizarPerfilRequest request) {
        return ResponseEntity.ok(usuarioService.editarUsuarioAdmin(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminar(@PathVariable Long id) {
        usuarioService.eliminarUsuario(id);
        return ResponseEntity.noContent().build();
    }
}

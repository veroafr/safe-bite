package com.safebite.backend.service;

import com.safebite.backend.dto.request.IntoleranciaRequest;
import com.safebite.backend.dto.response.IntoleranciaResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Intolerancia;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.repository.IntoleranciaRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Catalogo de intolerancias del sistema (predefinidas + las que agrega el admin).
 */
@Service
@RequiredArgsConstructor
public class IntoleranciaService {

    private final IntoleranciaRepository repository;

    // ---------- consultas ----------

    public List<IntoleranciaResponse> listarActivas() {
        return repository.findByActivaTrueOrderByOrdenAscNombreAsc().stream().map(IntoleranciaResponse::desde).toList();
    }

    public List<IntoleranciaResponse> listarTodas() {
        return repository.findAllByOrderByOrdenAscNombreAsc().stream().map(IntoleranciaResponse::desde).toList();
    }

    public List<Intolerancia> entidadesActivas() {
        return repository.findByActivaTrueOrderByOrdenAscNombreAsc();
    }

    /** Nombre legible de un codigo (o el codigo si no existe). */
    public String nombre(String codigo) {
        return repository.findByCodigo(codigo).map(Intolerancia::getNombre).orElse(codigo);
    }

    /** "Trigo, Leche, Soja" para usar en mensajes y prompts. */
    public String nombres(Collection<String> codigos) {
        if (codigos == null || codigos.isEmpty()) return "ninguna";
        Map<String, String> mapa = new HashMap<>();
        repository.findAll().forEach(i -> mapa.put(i.getCodigo(), i.getNombre()));
        return codigos.stream().map(c -> mapa.getOrDefault(c, c)).sorted().collect(Collectors.joining(", "));
    }

    /**
     * Limpia una lista de codigos que llega del cliente: pasa a mayusculas,
     * traduce codigos viejos (GLUTEN -> TRIGO, CENTENO, CEBADA, AVENA...) y
     * descarta los que no existen.
     */
    public Set<String> normalizar(Collection<String> codigos) {
        Set<String> resultado = new LinkedHashSet<>();
        if (codigos == null) return resultado;
        Set<String> existentes = repository.findAll().stream().map(Intolerancia::getCodigo).collect(Collectors.toSet());
        for (String c : codigos) {
            if (c == null || c.isBlank()) continue;
            String cod = c.trim().toUpperCase();
            if (TipoIntolerancia.LEGADO.containsKey(cod)) {
                resultado.addAll(TipoIntolerancia.LEGADO.get(cod));
            } else if (existentes.contains(cod)) {
                resultado.add(cod);
            }
        }
        return new HashSet<>(resultado);
    }

    // ---------- administracion ----------

    @Transactional
    public IntoleranciaResponse crear(IntoleranciaRequest req) {
        String nombre = req.getNombre().trim();
        if (repository.existsByNombreIgnoreCase(nombre)) {
            throw new BadRequestException("Ya existe una intolerancia con ese nombre");
        }
        String codigo = generarCodigo(nombre);
        int orden = req.getOrden() != null ? req.getOrden()
                : repository.findAll().stream().mapToInt(i -> i.getOrden() == null ? 0 : i.getOrden()).max().orElse(0) + 1;

        Intolerancia i = Intolerancia.builder()
                .codigo(codigo)
                .nombre(nombre)
                .nombreCientifico(vacioANull(req.getNombreCientifico()))
                .descripcion(vacioANull(req.getDescripcion()))
                .palabrasClave(palabrasClave(req.getPalabrasClave(), nombre))
                .activa(req.getActiva() == null || req.getActiva())
                .predefinida(false)
                .orden(orden)
                .build();
        return IntoleranciaResponse.desde(repository.save(i));
    }

    @Transactional
    public IntoleranciaResponse editar(Long id, IntoleranciaRequest req) {
        Intolerancia i = buscar(id);
        String nombre = req.getNombre().trim();
        if (!nombre.equalsIgnoreCase(i.getNombre()) && repository.existsByNombreIgnoreCase(nombre)) {
            throw new BadRequestException("Ya existe una intolerancia con ese nombre");
        }
        // El codigo no cambia: es lo que ya esta guardado en usuarios, productos, etc.
        i.setNombre(nombre);
        i.setNombreCientifico(vacioANull(req.getNombreCientifico()));
        i.setDescripcion(vacioANull(req.getDescripcion()));
        i.setPalabrasClave(palabrasClave(req.getPalabrasClave(), nombre));
        if (req.getActiva() != null) i.setActiva(req.getActiva());
        if (req.getOrden() != null) i.setOrden(req.getOrden());
        return IntoleranciaResponse.desde(repository.save(i));
    }

    @Transactional
    public IntoleranciaResponse cambiarEstado(Long id, boolean activa) {
        Intolerancia i = buscar(id);
        i.setActiva(activa);
        return IntoleranciaResponse.desde(repository.save(i));
    }

    /** Las predefinidas no se borran (solo se desactivan); las agregadas por el admin si. */
    @Transactional
    public void eliminar(Long id) {
        Intolerancia i = buscar(id);
        if (i.isPredefinida()) {
            throw new BadRequestException("Las intolerancias de la lista oficial no se pueden eliminar, solo desactivar");
        }
        repository.delete(i);
    }

    /** Crea las intolerancias predefinidas que falten. Se llama al iniciar la app. */
    @Transactional
    public void sembrarPredefinidas() {
        int orden = 1;
        for (TipoIntolerancia.Predefinida p : TipoIntolerancia.PREDEFINIDAS) {
            final int o = orden++;
            if (repository.existsByCodigo(p.codigo())) continue;
            repository.save(Intolerancia.builder()
                    .codigo(p.codigo())
                    .nombre(p.nombre())
                    .nombreCientifico(p.nombreCientifico())
                    .descripcion(p.descripcion())
                    .palabrasClave(p.palabrasClave())
                    .predefinida(true)
                    .activa(true)
                    .orden(o)
                    .build());
        }
    }

    private Intolerancia buscar(Long id) {
        return repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Intolerancia no encontrada"));
    }

    private String generarCodigo(String nombre) {
        String base = Normalizer.normalize(nombre, Normalizer.Form.NFD).replaceAll("\\p{M}", "")
                .toUpperCase().replaceAll("[^A-Z0-9]+", "_").replaceAll("^_+|_+$", "");
        if (base.isEmpty()) base = "INTOLERANCIA";
        if (base.length() > 50) base = base.substring(0, 50);
        String codigo = base;
        int n = 2;
        while (repository.existsByCodigo(codigo) || TipoIntolerancia.LEGADO.containsKey(codigo)) {
            codigo = base + "_" + n++;
        }
        return codigo;
    }

    private String palabrasClave(String valor, String nombre) {
        String v = valor == null ? "" : valor.trim();
        if (v.isEmpty()) return nombre.toLowerCase();
        return java.util.Arrays.stream(v.split(","))
                .map(String::trim).filter(s -> !s.isEmpty())
                .distinct().collect(Collectors.joining(","));
    }

    private String vacioANull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}

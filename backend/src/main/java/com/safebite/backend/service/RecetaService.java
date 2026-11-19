package com.safebite.backend.service;

import com.safebite.backend.dto.request.RecetaRequest;
import com.safebite.backend.dto.response.RecetaResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.Receta;
import com.safebite.backend.model.Rol;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.RecetaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;

/**
 * Recetas de tres orígenes:
 *  - ADMIN: cargadas por el equipo, se publican directamente ("verificadas");
 *  - USUARIO: enviadas por las personas, quedan PENDIENTES hasta que el admin las aprueba;
 *  - SPOONACULAR: el admin las busca en la API, las revisa y las publica. Solo se guarda
 *    id + título + imagen; el resto se pide en vivo y se traduce al abrirlas.
 * En todas, el analizador de SafeBite revisa los ingredientes contra las 21 intolerancias.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class RecetaService {

    private final RecetaRepository recetaRepository;
    private final IntoleranciaService intoleranciaService;
    private final AlergenoTextAnalyzer analizador;
    private final SpoonacularClient spoonacular;
    private final TraduccionRecetaService traduccion;

    // ================= Público =================

    /**
     * Solo recetas publicadas.
     * @param filtro intolerancias elegidas: solo se devuelven recetas libres de TODAS ellas.
     */
    public List<RecetaResponse> listar(Boolean esTip, Collection<String> filtro) {
        List<Receta> recetas = esTip != null ? recetaRepository.findByEsTip(esTip) : recetaRepository.findAll();
        Set<String> codigos = intoleranciaService.normalizar(filtro);

        return recetas.stream()
                .filter(Receta::estaPublicada)
                .filter(r -> codigos.isEmpty() || libreDe(r).containsAll(codigos))
                .sorted(Comparator.comparing(Receta::getFechaPublicacion, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(this::resumen)
                .toList();
    }

    /** Detalle. Las no publicadas solo las ve su autor o un administrador. */
    public RecetaResponse obtener(Long id, Usuario usuario) {
        Receta r = buscarEntidad(id);
        if (!r.estaPublicada() && !esAdmin(usuario) && !esAutor(r, usuario)) {
            throw new ResourceNotFoundException("Receta no encontrada");
        }
        return completa(r);
    }

    /** Una persona envía una receta: queda pendiente de aprobación. */
    @Transactional
    public RecetaResponse proponer(RecetaRequest request, Usuario usuario) {
        validarContenido(request);
        Receta receta = Receta.builder()
                .origen(Receta.ORIGEN_USUARIO)
                .estado(Receta.PENDIENTE)
                .publicadoPor(usuario)
                .esTip(false)
                .build();
        aplicar(receta, request);
        receta.setFechaPublicacion(LocalDateTime.now());
        return completa(recetaRepository.save(receta));
    }

    /** El autor corrige una receta suya: vuelve a revisión. */
    @Transactional
    public RecetaResponse editarPropuesta(Long id, RecetaRequest request, Usuario usuario) {
        Receta receta = buscarEntidad(id);
        if (!esAutor(receta, usuario) || !Receta.ORIGEN_USUARIO.equals(receta.getOrigen())) {
            throw new ResourceNotFoundException("Receta no encontrada");
        }
        validarContenido(request);
        aplicar(receta, request);
        receta.setEsTip(false);
        receta.setEstado(Receta.PENDIENTE);
        receta.setMotivoRechazo(null);
        receta.setFechaRevision(null);
        return completa(recetaRepository.save(receta));
    }

    public List<RecetaResponse> misPropuestas(Usuario usuario) {
        if (usuario == null) return List.of();
        return recetaRepository.findByPublicadoPorIdAndOrigenOrderByFechaPublicacionDesc(usuario.getId(), Receta.ORIGEN_USUARIO)
                .stream().map(this::resumen).toList();
    }

    // ================= Administración =================

    public List<RecetaResponse> listarPorEstado(String estado) {
        String e = estado == null || estado.isBlank() ? Receta.PENDIENTE : estado.toUpperCase();
        List<Receta> recetas = Receta.APROBADA.equals(e)
                ? recetaRepository.findAll().stream().filter(Receta::estaPublicada).toList()
                : recetaRepository.findByEstadoOrderByFechaPublicacionAsc(e);
        // Para moderar hace falta ver ingredientes y avisos: respuesta completa
        // (las de Spoonacular siempre están aprobadas, no se piden en vivo acá).
        return recetas.stream().map(r -> r.esDeSpoonacular() ? resumen(r) : completa(r)).toList();
    }

    @Transactional
    public RecetaResponse moderar(Long id, boolean aprobar, String motivo) {
        Receta r = buscarEntidad(id);
        r.setEstado(aprobar ? Receta.APROBADA : Receta.RECHAZADA);
        r.setMotivoRechazo(aprobar || motivo == null || motivo.isBlank() ? null : motivo.trim());
        r.setFechaRevision(LocalDateTime.now());
        return resumen(recetaRepository.save(r));
    }

    public Receta buscarEntidad(Long id) {
        return recetaRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Receta no encontrada"));
    }

    /** Receta cargada por el admin: se publica directamente. */
    @Transactional
    public RecetaResponse crear(RecetaRequest request, Usuario admin) {
        if (request.getTitulo() == null || request.getTitulo().isBlank()) throw new BadRequestException("Falta el título");
        Receta receta = Receta.builder()
                .origen(Receta.ORIGEN_ADMIN)
                .estado(Receta.APROBADA)
                .publicadoPor(admin)
                .build();
        aplicar(receta, request);
        receta.setEsTip(request.isEsTip());
        return completa(recetaRepository.save(receta));
    }

    /** El admin edita cualquier receta (incluida una enviada por un usuario antes de aprobarla). */
    @Transactional
    public RecetaResponse editar(Long id, RecetaRequest request) {
        Receta receta = buscarEntidad(id);
        if (receta.esDeSpoonacular()) {
            // De Spoonacular solo se puede cambiar lo propio de SafeBite.
            if (request.getTitulo() != null && !request.getTitulo().isBlank()) receta.setTitulo(request.getTitulo().trim());
            if (request.getLibreDe() != null) receta.setLibreDe(intoleranciaService.normalizar(request.getLibreDe()));
            if (request.getEtiquetas() != null) receta.setEtiquetas(new HashSet<>(request.getEtiquetas()));
            return resumen(recetaRepository.save(receta));
        }
        aplicar(receta, request);
        receta.setEsTip(request.isEsTip());
        return completa(recetaRepository.save(receta));
    }

    @Transactional
    public void eliminar(Long id) {
        if (!recetaRepository.existsById(id)) {
            throw new ResourceNotFoundException("Receta no encontrada");
        }
        recetaRepository.deleteById(id);
    }

    // ---------- Spoonacular (admin) ----------

    public Map<String, Object> buscarEnSpoonacular(String consulta, Collection<String> intolerancias, int pagina) {
        Set<String> codigos = intoleranciaService.normalizar(intolerancias);
        String enIngles = traduccion.traducirConsulta(consulta);
        int cantidad = 10;
        List<SpoonacularClient.Resultado> resultados = spoonacular.buscar(enIngles, codigos, cantidad, Math.max(0, pagina) * cantidad);

        Set<Long> importadas = new HashSet<>();
        for (Receta r : recetaRepository.findByOrigen(Receta.ORIGEN_SPOONACULAR)) importadas.add(r.getExternoId());

        List<String> titulos = traduccion.traducirTitulos(resultados.stream().map(SpoonacularClient.Resultado::titulo).toList());
        List<Map<String, Object>> lista = new ArrayList<>();
        for (int i = 0; i < resultados.size(); i++) {
            SpoonacularClient.Resultado r = resultados.get(i);
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("externoId", r.id());
            m.put("tituloOriginal", r.titulo());
            m.put("titulo", titulos.get(i));
            m.put("imagenUrl", r.imagen());
            m.put("yaImportada", importadas.contains(r.id()));
            lista.add(m);
        }
        Map<String, Object> respuesta = new LinkedHashMap<>();
        respuesta.put("consultaEnIngles", enIngles);
        respuesta.put("resultados", lista);
        respuesta.put("sinFiltroEnFuente", nombres(SpoonacularClient.sinEquivalente(codigos)));
        respuesta.put("cuota", spoonacular.estado());
        return respuesta;
    }

    /** Vista previa en vivo (traducida y analizada) antes de publicar. */
    public RecetaResponse vistaPreviaSpoonacular(long externoId, Collection<String> intolerancias) {
        Receta temporal = Receta.builder()
                .origen(Receta.ORIGEN_SPOONACULAR)
                .estado(Receta.PENDIENTE)
                .externoId(externoId)
                .libreDe(intoleranciaService.normalizar(intolerancias))
                .build();
        RecetaResponse r = completa(temporal);
        // Sugerencia: libre de lo buscado menos lo que el analizador encontró.
        Set<String> sugerido = new LinkedHashSet<>(temporal.getLibreDe());
        if (r.getDetectados() != null) sugerido.removeAll(r.getDetectados());
        r.setLibreDe(sugerido);
        return r;
    }

    /** Publica una receta de Spoonacular (la decisión del admin es la aprobación). */
    @Transactional
    public RecetaResponse importarDeSpoonacular(long externoId, String titulo, Collection<String> libreDe, Usuario admin) {
        if (recetaRepository.findFirstByExternoIdAndOrigen(externoId, Receta.ORIGEN_SPOONACULAR).isPresent()) {
            throw new BadRequestException("Esa receta ya está publicada en SafeBite.");
        }
        SpoonacularClient.Detalle d = spoonacular.detalle(externoId);
        Receta receta = Receta.builder()
                .origen(Receta.ORIGEN_SPOONACULAR)
                .estado(Receta.APROBADA)
                .externoId(externoId)
                .tituloOriginal(d.titulo())
                .titulo(titulo != null && !titulo.isBlank() ? titulo.trim() : d.titulo())
                .imagenUrl(d.imagen())
                .libreDe(intoleranciaService.normalizar(libreDe))
                .publicadoPor(admin)
                .fechaRevision(LocalDateTime.now())
                .build();
        return resumen(recetaRepository.save(receta));
    }

    public Map<String, Object> estadoSpoonacular() {
        return spoonacular.estado();
    }

    // ================= Interno =================

    /** Para listados: sin pedir nada a Spoonacular. */
    private RecetaResponse resumen(Receta r) {
        RecetaResponse resp = RecetaResponse.desde(r);
        if (r.esDeSpoonacular()) {
            resp.setFuenteUrl(urlSpoonacular(r));
            resp.setIngredientes(List.of());
            resp.setPasos(List.of());
        }
        return resp;
    }

    /** Detalle con ingredientes y pasos; para Spoonacular se piden en vivo y se traducen. */
    private RecetaResponse completa(Receta r) {
        RecetaResponse resp = RecetaResponse.desde(r);
        List<String> textoParaAnalizar = new ArrayList<>();

        if (r.esDeSpoonacular()) {
            resp.setFuenteUrl(urlSpoonacular(r));
            resp.setIngredientes(List.of());
            resp.setPasos(List.of());
            try {
                SpoonacularClient.Detalle d = spoonacular.detalle(r.getExternoId());
                textoParaAnalizar.addAll(d.ingredientes());
                if (resp.getTitulo() == null) resp.setTitulo(d.titulo());
                if (resp.getImagenUrl() == null) resp.setImagenUrl(d.imagen());
                resp.setTituloOriginal(d.titulo());
                resp.setTiempoPreparacionMinutos(d.minutos());
                resp.setPorciones(d.porciones());
                resp.setFuenteUrl(d.fuenteUrl() != null ? d.fuenteUrl() : d.spoonacularUrl());
                resp.setCreditos(d.creditos());

                Optional<TraduccionRecetaService.Traduccion> t = traduccion.traducir(d);
                if (t.isPresent()) {
                    resp.setDescripcion(t.get().resumen());
                    resp.setIngredientes(t.get().ingredientes());
                    resp.setPasos(t.get().pasos());
                    if (r.getTitulo() == null) resp.setTitulo(t.get().titulo());
                    resp.setTraducida(true);
                    textoParaAnalizar.addAll(t.get().ingredientes());
                } else {
                    resp.setDescripcion(d.resumen());
                    resp.setIngredientes(d.ingredientes());
                    resp.setPasos(d.pasos());
                    resp.setTraducida(false);
                    resp.setAviso("No se pudo traducir en este momento: se muestra la receta original en inglés.");
                }
            } catch (BadRequestException e) {
                resp.setAviso(e.getMessage() + " Podés abrir la receta en la fuente original.");
            }
        } else {
            if (r.getIngredientes() != null) textoParaAnalizar.addAll(r.getIngredientes());
        }

        Set<String> detectados = new LinkedHashSet<>(analizador.detectar(String.join("\n", textoParaAnalizar)));
        resp.setDetectados(detectados);
        Set<String> conflictos = new LinkedHashSet<>(libreDe(r));
        conflictos.retainAll(detectados);
        resp.setConflictos(conflictos);
        return resp;
    }

    private void validarContenido(RecetaRequest req) {
        if (req.getTitulo() == null || req.getTitulo().trim().length() < 3) {
            throw new BadRequestException("Escribí un nombre para la receta");
        }
        if (req.getIngredientes() == null || req.getIngredientes().stream().noneMatch(i -> i != null && !i.isBlank())) {
            throw new BadRequestException("Agregá al menos un ingrediente");
        }
        if (req.getPasos() == null || req.getPasos().stream().noneMatch(p -> p != null && !p.isBlank())) {
            throw new BadRequestException("Agregá al menos un paso de preparación");
        }
    }

    private void aplicar(Receta receta, RecetaRequest request) {
        if (request.getTitulo() != null) receta.setTitulo(request.getTitulo().trim());
        receta.setDescripcion(vacioANull(request.getDescripcion()));
        receta.setTiempoPreparacionMinutos(request.getTiempoPreparacionMinutos());
        receta.setDificultad(vacioANull(request.getDificultad()));
        if (request.getImagenUrl() != null) receta.setImagenUrl(vacioANull(request.getImagenUrl()));
        if (request.getImagenBase64() != null) {
            receta.setImagenDatos(request.getImagenBase64().isBlank()
                    ? null : ImagenRestauranteUtil.ajustar(request.getImagenBase64(), 1000));
        }
        if (request.getEtiquetas() != null) receta.setEtiquetas(new HashSet<>(request.getEtiquetas()));
        if (request.getLibreDe() != null) receta.setLibreDe(intoleranciaService.normalizar(request.getLibreDe()));
        if (request.getIngredientes() != null) receta.setIngredientes(limpiar(request.getIngredientes()));
        if (request.getPasos() != null) receta.setPasos(limpiar(request.getPasos()));
    }

    private static List<String> limpiar(List<String> lista) {
        List<String> r = new ArrayList<>();
        for (String s : lista) if (s != null && !s.isBlank()) r.add(s.trim());
        return r;
    }

    private static String vacioANull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }

    private static boolean esAdmin(Usuario u) {
        return u != null && u.getRol() == Rol.ADMINISTRADOR;
    }

    private static boolean esAutor(Receta r, Usuario u) {
        return u != null && r.getPublicadoPor() != null && Objects.equals(r.getPublicadoPor().getId(), u.getId());
    }

    private List<String> nombres(Collection<String> codigos) {
        return codigos.stream().map(intoleranciaService::nombre).toList();
    }

    /** Página de la receta en spoonacular.com (enlace de atribución). */
    private static String urlSpoonacular(Receta r) {
        String base = r.getTituloOriginal() != null ? r.getTituloOriginal() : "receta";
        String slug = java.text.Normalizer.normalize(base, java.text.Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "").toLowerCase().replaceAll("[^a-z0-9]+", "-").replaceAll("(^-|-$)", "");
        return "https://spoonacular.com/recipes/" + slug + "-" + r.getExternoId();
    }

    /** libreDe + lo que se deduce de etiquetas viejas tipo "Sin Gluten" / "Sin Lactosa". */
    private Set<String> libreDe(Receta receta) {
        Set<String> r = new HashSet<>(receta.getLibreDe());
        for (String etiqueta : receta.getEtiquetas()) {
            String e = etiqueta == null ? "" : etiqueta.trim().toLowerCase();
            if (e.equals("sin gluten") || e.equals("sin tacc")) r.addAll(TipoIntolerancia.LEGADO.get("GLUTEN"));
            if (e.equals("sin lactosa")) r.addAll(TipoIntolerancia.LEGADO.get("LACTOSA"));
            if (e.equals("sin frutos secos")) r.addAll(TipoIntolerancia.LEGADO.get("FRUTOS_SECOS"));
            if (e.equals("sin mariscos")) r.addAll(TipoIntolerancia.LEGADO.get("MARISCOS"));
        }
        return r;
    }
}

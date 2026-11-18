package com.safebite.backend.service;

import com.safebite.backend.model.Intolerancia;
import com.safebite.backend.model.Noticia;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.repository.NoticiaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.ByteArrayInputStream;
import java.net.URI;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.text.Normalizer;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.regex.Pattern;

/**
 * Importa noticias de Uruguay y Brasil sobre restricciones alimentarias
 * desde canales RSS de Google Noticias, que reúnen a los medios de cada país:
 * <ul>
 *   <li>búsquedas generales: celiaquía, alergias, lactosa, etiquetado y normativa;</li>
 *   <li>una búsqueda por cada restricción del catálogo (los 21 alérgenos de
 *       ANVISA y las que agregue el administrador), en español para Uruguay y
 *       en portugués para Brasil.</li>
 * </ul>
 * Cada noticia se etiqueta con TODAS las restricciones que menciona, usando
 * el nombre y las palabras clave del catálogo, para que funcione el filtro de
 * restricciones de la pantalla de noticias. Los canales se pueden reemplazar
 * con la variable NOTICIAS_RSS_FEEDS ("UY|url;BR|url;...").
 *
 * De cada noticia se guarda solo el título, un resumen corto, el medio, la
 * fecha y el enlace: el texto completo se lee en el sitio original.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class NoticiaRssService {

    private final NoticiaRepository noticiaRepository;
    private final IntoleranciaService intoleranciaService;

    /** Resultado de la última importación (para mostrarlo en el panel). */
    private volatile ResultadoImportacion ultimoResultado;
    private volatile LocalDateTime ultimaImportacion;

    @Value("${safebite.noticias.rss.habilitado:true}")
    private boolean habilitado;

    @Value("${safebite.noticias.rss.feeds:}")
    private String feedsConfigurados;

    /** Noticias más viejas que esto no se importan. */
    @Value("${safebite.noticias.rss.dias-maximos:60}")
    private int diasMaximos;

    /** Máximo de noticias nuevas por canal en cada importación. */
    @Value("${safebite.noticias.rss.maximo-por-canal:8}")
    private int maximoPorCanal;

    private final AtomicBoolean enCurso = new AtomicBoolean(false);

    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(15))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();

    /** Búsquedas por defecto: tres por país. */
    private static final String[][] BUSQUEDAS = {
            {"UY", "celíacos OR celiaquía OR \"sin gluten\" OR \"sin TACC\" Uruguay"},
            {"UY", "alérgenos OR etiquetado OR rotulado alimentos Uruguay"},
            {"UY", "\"alergia alimentaria\" OR \"intolerancia a la lactosa\" Uruguay"},
            {"BR", "\"doença celíaca\" OR celíacos OR \"sem glúten\""},
            {"BR", "rotulagem alergênicos OR \"rotulagem de alimentos\" Anvisa"},
            {"BR", "\"alergia alimentar\" OR \"intolerância à lactose\""},
    };

    /** Al menos una de estas palabras debe aparecer: evita noticias que no vienen al caso. */
    private static final List<String> PALABRAS_RELEVANTES = List.of(
            "celiac", "celiaq", "gluten", "tacc", "alergen", "alergi", "alergic", "lactosa", "lactose",
            "intoleranc", "etiquetado", "rotulado", "rotulagem", "anafila", "anvisa");

    /** Nombre en portugués de las restricciones predefinidas (búsquedas de Brasil). */
    private static final Map<String, String> NOMBRES_PT = Map.ofEntries(
            Map.entry("TRIGO", "trigo"), Map.entry("CENTENO", "centeio"), Map.entry("CEBADA", "cevada"),
            Map.entry("AVENA", "aveia"), Map.entry("CRUSTACEOS", "crustáceos"), Map.entry("HUEVO", "ovo"),
            Map.entry("PESCADO", "peixe"), Map.entry("MANI", "amendoim"), Map.entry("SOJA", "soja"),
            Map.entry("LECHE", "leite"), Map.entry("ALMENDRA", "amêndoa"), Map.entry("AVELLANA", "avelã"),
            Map.entry("CASTANA_CAJU", "castanha de caju"), Map.entry("CASTANA_PARA", "castanha-do-pará"),
            Map.entry("MACADAMIA", "macadâmia"), Map.entry("NUEZ", "nozes"), Map.entry("PECAN", "noz-pecã"),
            Map.entry("PISTACHO", "pistache"), Map.entry("PINON", "pinhão"), Map.entry("CASTANA", "castanha"),
            Map.entry("LATEX", "látex"));

    /**
     * Palabras clave del catálogo que en una noticia significan otra cosa
     * (Malta el país, "clara" el adjetivo...): no se usan para etiquetar.
     */
    private static final Set<String> CLAVES_AMBIGUAS = Set.of(
            "malta", "clara", "gema", "nata", "miso", "yema", "manteca", "crema de leche", "queso", "queijo",
            "marisco", "mariscos", "caju", "tuna", "fish", "egg", "milk", "oat", "oats", "crab", "lobster",
            "rye", "soy", "whey", "ghee", "gluten");

    /** Pausa entre canales para no saturar al proveedor del RSS. */
    private static final long PAUSA_ENTRE_CANALES_MS = 1200;

    /** codigoBuscado: la restricción de la búsqueda (null en las generales). */
    private record Canal(String pais, String url, String codigoBuscado, String consulta) {}

    /** Palabras de una restricción, ya normalizadas, para reconocerla en un texto. */
    private record Reconocedor(String codigo, Pattern patron) {}

    public record ResultadoImportacion(int canales, int revisadas, int nuevas, List<String> errores) {}

    /** Se ejecuta a los 2 minutos de arrancar y después cada 6 horas. */
    @Scheduled(initialDelayString = "${safebite.noticias.rss.demora-inicial:PT2M}",
            fixedDelayString = "${safebite.noticias.rss.intervalo:PT6H}")
    public void importarProgramado() {
        if (!habilitado) return;
        ResultadoImportacion r = importar();
        log.info("Noticias RSS: {} nuevas de {} revisadas ({} errores)", r.nuevas(), r.revisadas(), r.errores().size());
    }

    /**
     * Importación pedida desde el panel: corre en segundo plano (revisa unos
     * 50 canales y tarda alrededor de un minuto) y devuelve enseguida.
     */
    public Map<String, Object> importarEnSegundoPlano() {
        Map<String, Object> r = new LinkedHashMap<>();
        if (enCurso.get()) {
            r.put("iniciada", false);
            r.put("mensaje", "Ya hay una importación en curso. Las noticias nuevas aparecen en uno o dos minutos.");
        } else {
            CompletableFuture.runAsync(this::importar);
            r.put("iniciada", true);
            r.put("mensaje", "Importación iniciada. Las noticias nuevas aparecen en uno o dos minutos.");
        }
        r.put("ultimaImportacion", ultimaImportacion == null ? null : ultimaImportacion.toString());
        r.put("ultimoResultado", ultimoResultado);
        return r;
    }

    public ResultadoImportacion importar() {
        if (!enCurso.compareAndSet(false, true)) {
            return new ResultadoImportacion(0, 0, 0, List.of("Ya hay una importación en curso"));
        }
        try {
            List<Canal> canales = canales();
            List<Reconocedor> reconocedores = reconocedores();
            List<String> errores = new ArrayList<>();
            int revisadas = 0;
            int nuevas = 0;
            boolean primero = true;
            for (Canal canal : canales) {
                if (!primero) {
                    try {
                        Thread.sleep(PAUSA_ENTRE_CANALES_MS);
                    } catch (InterruptedException ie) {
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
                primero = false;
                try {
                    List<Noticia> items = leerCanal(canal, reconocedores);
                    revisadas += items.size();
                    int nuevasCanal = 0;
                    for (Noticia n : items) {
                        if (nuevasCanal >= maximoPorCanal) break;
                        if (guardarSiEsNueva(n)) {
                            nuevas++;
                            nuevasCanal++;
                        }
                    }
                } catch (Exception e) {
                    log.warn("No se pudo leer el canal RSS {}: {}", canal.url(), e.getMessage());
                    errores.add(canal.pais() + ": " + e.getMessage());
                }
            }
            limpiarAntiguas();
            ResultadoImportacion resultado = new ResultadoImportacion(canales.size(), revisadas, nuevas, errores);
            ultimoResultado = resultado;
            ultimaImportacion = LocalDateTime.now();
            return resultado;
        } finally {
            enCurso.set(false);
        }
    }

    private List<Canal> canales() {
        List<Canal> canales = new ArrayList<>();
        if (feedsConfigurados != null && !feedsConfigurados.isBlank()) {
            for (String parte : feedsConfigurados.split(";")) {
                String[] p = parte.trim().split("\\|", 2);
                if (p.length == 2 && !p[1].isBlank()) canales.add(new Canal(p[0].trim().toUpperCase(), p[1].trim(), null, null));
            }
            if (!canales.isEmpty()) return canales;
        }
        for (String[] b : BUSQUEDAS) {
            canales.add(new Canal(b[0], urlGoogleNoticias(b[0], b[1]), null, b[1]));
        }
        // Una búsqueda por restricción y por país.
        for (Intolerancia i : catalogo()) {
            String es = i.getNombre().toLowerCase(Locale.ROOT);
            String pt = NOMBRES_PT.getOrDefault(i.getCodigo(), es);
            String qUy = "(alergia OR alérgicos OR intolerancia) \"" + es + "\" Uruguay";
            String qBr = "(alergia OR alérgicos OR intolerância) \"" + pt + "\"";
            canales.add(new Canal("UY", urlGoogleNoticias("UY", qUy), i.getCodigo(), qUy));
            canales.add(new Canal("BR", urlGoogleNoticias("BR", qBr), i.getCodigo(), qBr));
        }
        return canales;
    }

    private static String urlGoogleNoticias(String pais, String consulta) {
        String q = URLEncoder.encode(consulta + " when:60d", StandardCharsets.UTF_8);
        return "BR".equals(pais)
                ? "https://news.google.com/rss/search?q=" + q + "&hl=pt-BR&gl=BR&ceid=BR:pt-419"
                : "https://news.google.com/rss/search?q=" + q + "&hl=es-419&gl=UY&ceid=UY:es-419";
    }

    /** Respaldo: Bing Noticias, por si Google no responde al servidor. */
    private static String urlBingNoticias(String pais, String consulta) {
        String q = URLEncoder.encode(consulta, StandardCharsets.UTF_8);
        return "BR".equals(pais)
                ? "https://www.bing.com/news/search?q=" + q + "&format=rss&setlang=pt-BR&cc=BR&qft=sortbydate%3d%221%22"
                : "https://www.bing.com/news/search?q=" + q + "&format=rss&setlang=es&cc=UY&qft=sortbydate%3d%221%22";
    }

    private List<Intolerancia> catalogo() {
        try {
            return intoleranciaService.entidadesActivas();
        } catch (Exception e) {
            log.warn("No se pudo leer el catálogo de restricciones: {}", e.getMessage());
            return List.of();
        }
    }

    /**
     * Un patrón por restricción con su nombre y sus palabras clave (sin las
     * ambiguas), como palabras completas y aceptando plurales.
     */
    private List<Reconocedor> reconocedores() {
        List<Reconocedor> lista = new ArrayList<>();
        for (Intolerancia i : catalogo()) {
            Set<String> terminos = new java.util.LinkedHashSet<>();
            terminos.add(normalizar(i.getNombre()).trim());
            String pt = NOMBRES_PT.get(i.getCodigo());
            if (pt != null) terminos.add(normalizar(pt).trim());
            if (i.getPalabrasClave() != null) {
                for (String c : i.getPalabrasClave().split(",")) {
                    String t = normalizar(c).trim();
                    if (t.length() >= 3 && !CLAVES_AMBIGUAS.contains(t)) terminos.add(t);
                }
            }
            String alternativas = terminos.stream()
                    .filter(t -> !t.isBlank())
                    .map(t -> Pattern.quote(t).replace(" ", "\\E[\\s-]+\\Q"))
                    .reduce((a, b) -> a + "|" + b)
                    .orElse(null);
            if (alternativas == null) continue;
            lista.add(new Reconocedor(i.getCodigo(),
                    Pattern.compile("(?<![a-z])(?:" + alternativas + ")(?:s|es)?(?![a-z])")));
        }
        return lista;
    }

    private List<Noticia> leerCanal(Canal canal, List<Reconocedor> reconocedores) throws Exception {
        try {
            return leerUrl(canal, canal.url(), reconocedores);
        } catch (Exception e) {
            if (canal.consulta() == null) throw e;
            // Google a veces rechaza pedidos de servidores: se prueba con Bing.
            log.info("Google Noticias falló ({}), se usa Bing para: {}", e.getMessage(), canal.consulta());
            try {
                return leerUrl(canal, urlBingNoticias(canal.pais(), canal.consulta()), reconocedores);
            } catch (Exception e2) {
                throw new IllegalStateException("Google: " + e.getMessage() + " / Bing: " + e2.getMessage());
            }
        }
    }

    private List<Noticia> leerUrl(Canal canal, String url, List<Reconocedor> reconocedores) throws Exception {
        HttpRequest pedido = HttpRequest.newBuilder(URI.create(url))
                .timeout(Duration.ofSeconds(25))
                .header("User-Agent", "Mozilla/5.0 (compatible; SafeBite/1.0; +https://safebiteapp.netlify.app)")
                .header("Accept", "application/rss+xml, application/xml, text/xml")
                .GET()
                .build();
        HttpResponse<byte[]> resp = http.send(pedido, HttpResponse.BodyHandlers.ofByteArray());
        if (resp.statusCode() != 200) {
            throw new IllegalStateException("HTTP " + resp.statusCode());
        }

        Document doc = parser().parse(new ByteArrayInputStream(resp.body()));
        NodeList items = doc.getElementsByTagName("item");
        LocalDateTime limite = LocalDateTime.now().minusDays(diasMaximos);
        List<Noticia> resultado = new ArrayList<>();

        for (int i = 0; i < items.getLength(); i++) {
            Element item = (Element) items.item(i);
            String titulo = texto(item, "title");
            String enlace = texto(item, "link");
            if (titulo == null || enlace == null) continue;

            String fuente = texto(item, "source");
            if (fuente == null) fuente = texto(item, "News:Source"); // Bing
            enlace = enlaceDirecto(enlace);
            if (fuente != null && titulo.endsWith(" - " + fuente)) {
                titulo = titulo.substring(0, titulo.length() - fuente.length() - 3).trim();
            }
            String resumen = limpiarHtml(texto(item, "description"));
            // En Google Noticias la descripción repite el título y el medio: no aporta.
            if (resumen != null && (resumen.startsWith(titulo) || resumen.length() < 40)) resumen = null;

            String combinado = normalizar(titulo + " " + (resumen == null ? "" : resumen));
            if (PALABRAS_RELEVANTES.stream().noneMatch(combinado::contains)) continue;

            LocalDateTime fecha = fecha(texto(item, "pubDate"));
            if (fecha.isBefore(limite)) continue;

            resultado.add(Noticia.builder()
                    .titulo(recortar(titulo, 250))
                    .resumen(recortar(resumen, 400))
                    .fuente(recortar(fuente, 200))
                    .urlOriginal(recortar(enlace, 1500))
                    .pais(canal.pais())
                    .origen("RSS")
                    .oculta(false)
                    .fechaPublicacion(fecha)
                    .etiquetas(etiquetas(combinado, canal.pais()))
                    .intolerancias(intolerancias(combinado, reconocedores, canal.codigoBuscado()))
                    .build());
        }
        return resultado;
    }

    private boolean guardarSiEsNueva(Noticia n) {
        if (noticiaRepository.existsByUrlOriginal(n.getUrlOriginal())) return false;
        // El mismo título publicado en varios medios o en varias búsquedas.
        if (noticiaRepository.existsByTituloIgnoreCase(n.getTitulo())) return false;
        noticiaRepository.save(n);
        return true;
    }

    /** Las importadas de hace más de 6 meses se borran (las ocultas también). */
    private void limpiarAntiguas() {
        try {
            List<Noticia> viejas = noticiaRepository.findByOrigenAndFechaPublicacionBefore(
                    "RSS", LocalDateTime.now().minusDays(180));
            noticiaRepository.deleteAll(viejas);
        } catch (Exception e) {
            log.warn("No se pudieron borrar las noticias importadas antiguas: {}", e.getMessage());
        }
    }

    // ---------- clasificación ----------

    private static Set<String> etiquetas(String texto, String pais) {
        Set<String> etiquetas = new HashSet<>();
        etiquetas.add("UY".equals(pais) ? "Uruguay" : "Brasil");
        if (contiene(texto, "ley ", "lei ", "decreto", "resolucion", "rdc", "anvisa", "msp", "normativa",
                "regulac", "regulament", "proyecto de ley", "projeto de lei")) {
            etiquetas.add("Legislación");
        }
        if (contiene(texto, "etiquetado", "rotulado", "rotulagem", "etiqueta", "rotulo")) etiquetas.add("Etiquetado");
        if (contiene(texto, "celiac", "celiaq", "gluten", "tacc")) etiquetas.add("Gluten");
        if (contiene(texto, "lactosa", "lactose")) etiquetas.add("Lactosa");
        if (contiene(texto, "alergi", "alergen")) etiquetas.add("Alergias");
        return etiquetas;
    }

    /**
     * Restricciones que menciona la noticia, según el catálogo. Celiaquía,
     * gluten y "sin TACC" equivalen a los cuatro cereales con gluten. Si la
     * noticia vino de la búsqueda de una restricción, se incluye esa también.
     */
    static Set<String> intolerancias(String texto, List<Reconocedor> reconocedores, String codigoBuscado) {
        Set<String> codigos = new HashSet<>();
        for (Reconocedor r : reconocedores) {
            if (r.patron().matcher(texto).find()) codigos.add(r.codigo());
        }
        if (contiene(texto, "celiac", "celiaq", "gluten", "tacc")) codigos.addAll(TipoIntolerancia.GRUPO_GLUTEN);
        if (contiene(texto, "lactosa", "lactose")) codigos.add(TipoIntolerancia.LECHE);
        if (codigoBuscado != null) codigos.add(codigoBuscado);
        return codigos;
    }

    private static boolean contiene(String texto, String... palabras) {
        for (String p : palabras) if (texto.contains(p)) return true;
        return false;
    }

    // ---------- utilidades ----------

    private static DocumentBuilder parser() throws Exception {
        DocumentBuilderFactory f = DocumentBuilderFactory.newInstance();
        // Protección contra XML malicioso (entidades externas).
        f.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        f.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
        f.setFeature("http://xml.org/sax/features/external-general-entities", false);
        f.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        f.setExpandEntityReferences(false);
        f.setNamespaceAware(false);
        return f.newDocumentBuilder();
    }

    /** Los enlaces de Bing pasan por un redireccionador: se toma la URL real. */
    static String enlaceDirecto(String enlace) {
        if (enlace == null || !enlace.contains("bing.com/news/apiclick")) return enlace;
        int i = enlace.indexOf("url=");
        if (i < 0) return enlace;
        String resto = enlace.substring(i + 4);
        int fin = resto.indexOf('&');
        if (fin >= 0) resto = resto.substring(0, fin);
        try {
            return java.net.URLDecoder.decode(resto, StandardCharsets.UTF_8);
        } catch (Exception e) {
            return enlace;
        }
    }

    private static String texto(Element padre, String etiqueta) {
        NodeList l = padre.getElementsByTagName(etiqueta);
        if (l.getLength() == 0) return null;
        Node n = l.item(0);
        String t = n.getTextContent();
        return t == null || t.isBlank() ? null : t.trim();
    }

    private static final Map<String, String> ENTIDADES = new LinkedHashMap<>();
    static {
        ENTIDADES.put("&nbsp;", " ");
        ENTIDADES.put("&quot;", "\"");
        ENTIDADES.put("&#39;", "'");
        ENTIDADES.put("&lt;", "<");
        ENTIDADES.put("&gt;", ">");
        ENTIDADES.put("&amp;", "&");
    }

    static String limpiarHtml(String html) {
        if (html == null) return null;
        String t = html.replaceAll("(?s)<[^>]*>", " ");
        for (Map.Entry<String, String> e : ENTIDADES.entrySet()) t = t.replace(e.getKey(), e.getValue());
        t = t.replaceAll("\\s+", " ").trim();
        return t.isEmpty() ? null : t;
    }

    static String normalizar(String s) {
        String sinTildes = Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll("\\p{M}", "");
        return " " + sinTildes.toLowerCase(Locale.ROOT) + " ";
    }

    private static LocalDateTime fecha(String pubDate) {
        if (pubDate == null) return LocalDateTime.now();
        try {
            return ZonedDateTime.parse(pubDate, DateTimeFormatter.RFC_1123_DATE_TIME)
                    .withZoneSameInstant(ZoneId.of("America/Montevideo"))
                    .toLocalDateTime();
        } catch (Exception e) {
            return LocalDateTime.now();
        }
    }

    private static String recortar(String s, int max) {
        if (s == null) return null;
        return s.length() <= max ? s : s.substring(0, max - 1).trim() + "…";
    }
}

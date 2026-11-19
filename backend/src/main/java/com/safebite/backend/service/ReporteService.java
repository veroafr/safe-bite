package com.safebite.backend.service;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import com.safebite.backend.dto.response.ReporteResponse;
import com.safebite.backend.dto.response.ReporteResponse.Dato;
import com.safebite.backend.dto.response.ReporteResponse.Serie;
import com.safebite.backend.model.*;
import com.safebite.backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Reportes y estadísticas del panel de administración: totales y series
 * para graficar, y el mismo contenido exportado a PDF (con gráficos de barras).
 */
@Service
@RequiredArgsConstructor
public class ReporteService {

    private static final String[] MESES = {"Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"};

    private final UsuarioRepository usuarioRepository;
    private final RestauranteRepository restauranteRepository;
    private final RecetaRepository recetaRepository;
    private final NoticiaRepository noticiaRepository;
    private final ProductoRepository productoRepository;
    private final AlertaRepository alertaRepository;
    private final EvaluacionRepository evaluacionRepository;
    private final UsoIaRepository usoIaRepository;
    private final SolicitudRecuperacionRepository recuperacionRepository;
    private final IntoleranciaService intoleranciaService;
    private final TraduccionContenidoService traduccion;

    public ReporteResponse obtenerEstadisticas() {
        ReporteResponse r = calcular();
        if (TraduccionRecetaService.pidePortugues()) {
            r.setSeries(r.getSeries().stream().map(s -> new Serie(s.clave(), t(s.titulo()), t(s.descripcion()), s.tipo(), t(s.unidad()),
                    s.datos().stream().map(d -> new Dato(t(d.etiqueta()), d.valor())).toList())).toList());
        }
        return r;
    }

    private ReporteResponse calcular() {
        List<Usuario> usuarios = usuarioRepository.findAll().stream().filter(u -> u.getRol() == Rol.USUARIO).toList();
        List<Producto> productos = productoRepository.findAll();
        List<Receta> recetas = recetaRepository.findAll().stream().filter(r -> !r.isEsTip()).toList();
        List<Evaluacion> resenas = evaluacionRepository.findAll();
        List<Noticia> noticias = noticiaRepository.findAll().stream().filter(n -> !Boolean.TRUE.equals(n.getOculta())).toList();
        List<Alerta> alertas = alertaRepository.findAll();
        List<Restaurante> restaurantes = restauranteRepository.findAll();

        List<Serie> series = new ArrayList<>();

        // 1. Registros por mes (últimos 6 meses)
        series.add(new Serie("usuariosPorMes", "Usuarios nuevos por mes", "Registros de los últimos 6 meses",
                "columnas", "usuarios", porMes(usuarios, Usuario::getFechaRegistro, 6)));

        // 2. Usuarios por intolerancia
        Map<String, Long> porIntolerancia = new HashMap<>();
        for (Usuario u : usuarios) for (String c : u.getIntolerancias()) porIntolerancia.merge(c, 1L, Long::sum);
        series.add(new Serie("usuariosPorIntolerancia", "Usuarios por intolerancia",
                "Cuántas personas declararon cada restricción", "barras", "usuarios",
                ordenados(porIntolerancia, intoleranciaService::nombre, 0)));

        // 3. Usuarios por país
        series.add(new Serie("usuariosPorPais", "Usuarios por país", null, "barras", "usuarios",
                contar(usuarios, u -> texto(u.getPais(), "Sin indicar"))));

        // 4. Productos por origen y verificación
        series.add(new Serie("productosPorOrigen", "Productos por origen", null, "barras", "productos",
                contar(productos, p -> switch (p.getOrigen() == null ? OrigenProducto.ADMIN : p.getOrigen()) {
                    case OPEN_FOOD_FACTS -> "Open Food Facts";
                    case USUARIO -> "Aportados por usuarios";
                    default -> "Cargados por el admin";
                })));

        // 5. Recetas publicadas por origen
        series.add(new Serie("recetasPorOrigen", "Recetas publicadas por origen", null, "barras", "recetas",
                contar(recetas.stream().filter(Receta::estaPublicada).toList(), r -> switch (r.origenEfectivo()) {
                    case Receta.ORIGEN_USUARIO -> "Comunidad";
                    case Receta.ORIGEN_SPOONACULAR -> "Spoonacular";
                    default -> "Equipo SafeBite";
                })));

        // 6. Restaurantes mejor puntuados
        Map<String, Double> rating = new LinkedHashMap<>();
        restaurantes.stream()
                .filter(r -> r.getRatingPromedio() != null && r.getRatingPromedio() > 0)
                .sorted(Comparator.comparing(Restaurante::getRatingPromedio).reversed())
                .limit(8)
                .forEach(r -> rating.put(r.getNombre(), r.getRatingPromedio()));
        series.add(new Serie("restaurantesRating", "Restaurantes mejor puntuados", "Promedio de estrellas (reseñas aprobadas)",
                "barras", "estrellas", rating.entrySet().stream().map(e -> new Dato(e.getKey(), e.getValue())).toList()));

        // 7. Reseñas por estado
        series.add(new Serie("resenasPorEstado", "Reseñas por estado", null, "barras", "reseñas",
                contar(resenas, e -> switch (e.getEstado() == null ? Evaluacion.APROBADA : e.getEstado()) {
                    case Evaluacion.PENDIENTE -> "Pendientes";
                    case Evaluacion.RECHAZADA -> "Rechazadas";
                    default -> "Aprobadas";
                })));

        // 8. Alertas por estado y por tipo
        series.add(new Serie("alertasPorEstado", "Alertas por estado", null, "barras", "alertas",
                contar(alertas, a -> switch (a.getEstado()) {
                    case PENDIENTE -> "Pendientes";
                    case ACEPTADA -> "Aceptadas";
                    case DENEGADA -> "Denegadas";
                })));
        series.add(new Serie("alertasPorTipo", "Alertas por tipo", null, "barras", "alertas",
                contar(alertas, a -> switch (a.getTipo()) {
                    case RESTAURANTE -> "Restaurantes";
                    case PRODUCTO -> "Productos";
                    case COMENTARIO -> "Comentarios";
                })));

        // 9. Noticias por país
        series.add(new Serie("noticiasPorPais", "Noticias por país", null, "barras", "noticias",
                contar(noticias, n -> "UY".equals(n.getPais()) ? "Uruguay" : "BR".equals(n.getPais()) ? "Brasil" : "Cargadas a mano")));

        // 10. Uso de inteligencia artificial por mes
        series.add(new Serie("iaPorMes", "Consultas de IA por mes", "Lectura de paquetes y traducciones (Claude y Gemini)",
                "columnas", "consultas", porMes(usoIaRepository.findAll(), UsoIa::getFecha, 6)));

        return ReporteResponse.builder()
                .generado(LocalDateTime.now())
                .totalUsuarios(usuarios.size())
                .usuariosActivos(usuarios.stream().filter(Usuario::isActivo).count())
                .totalRestaurantes(restaurantes.size())
                .totalRecetas(recetas.stream().filter(Receta::estaPublicada).count())
                .totalNoticias(noticias.size())
                .totalProductos(productos.size())
                .totalResenas(resenas.stream().filter(Evaluacion::estaPublicada).count())
                .alertasPendientes(alertaRepository.countByEstado(EstadoAlerta.PENDIENTE))
                .alertasAceptadas(alertaRepository.countByEstado(EstadoAlerta.ACEPTADA))
                .alertasDenegadas(alertaRepository.countByEstado(EstadoAlerta.DENEGADA))
                .productosPendientes(productos.stream().filter(p -> !p.isVerificado()).count())
                .recetasPendientes(recetas.stream().filter(r -> Receta.PENDIENTE.equals(r.getEstado())).count())
                .resenasPendientes(resenas.stream().filter(e -> Evaluacion.PENDIENTE.equals(e.getEstado())).count())
                .recuperacionesPendientes(recuperacionRepository.countByEstado(SolicitudRecuperacion.PENDIENTE))
                .series(series)
                .build();
    }

    // ---------- PDF ----------

    private static final Color VERDE = new Color(0x14, 0x76, 0x3F);
    private static final Color VERDE_OSCURO = new Color(0x0B, 0x4D, 0x2C);
    private static final Color VERDE_CLARO = new Color(0xE4, 0xF1, 0xE8);
    private static final Color GRIS = new Color(0x6B, 0x72, 0x80);

    public byte[] exportarPdf() {
        ReporteResponse r = obtenerEstadisticas();
        try (ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Document doc = new Document(PageSize.A4, 40, 40, 40, 40);
            PdfWriter.getInstance(doc, out);
            doc.open();

            Font titulo = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 20, VERDE_OSCURO);
            Font sub = FontFactory.getFont(FontFactory.HELVETICA, 10, GRIS);
            Font seccion = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13, VERDE_OSCURO);
            Font normal = FontFactory.getFont(FontFactory.HELVETICA, 10);
            Font negrita = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 10);
            Font chico = FontFactory.getFont(FontFactory.HELVETICA, 8, GRIS);

            Paragraph t = new Paragraph(t("SafeBite - Reporte de estadísticas"), titulo);
            doc.add(t);
            Paragraph f = new Paragraph(t("Generado el") + " " + r.getGenerado().format(DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm")), sub);
            f.setSpacingAfter(16);
            doc.add(f);

            // Resumen
            doc.add(new Paragraph(t("Resumen"), seccion));
            PdfPTable resumen = new PdfPTable(4);
            resumen.setWidthPercentage(100);
            resumen.setSpacingBefore(8);
            resumen.setSpacingAfter(18);
            Object[][] totales = {
                    {"Usuarios", r.getTotalUsuarios()}, {"Usuarios activos", r.getUsuariosActivos()},
                    {"Restaurantes", r.getTotalRestaurantes()}, {"Reseñas publicadas", r.getTotalResenas()},
                    {"Recetas publicadas", r.getTotalRecetas()}, {"Productos", r.getTotalProductos()},
                    {"Noticias", r.getTotalNoticias()}, {"Alertas pendientes", r.getAlertasPendientes()},
                    {"Productos por revisar", r.getProductosPendientes()}, {"Recetas por aprobar", r.getRecetasPendientes()},
                    {"Reseñas por aprobar", r.getResenasPendientes()}, {"Pedidos de contraseña", r.getRecuperacionesPendientes()},
            };
            for (Object[] fila : totales) {
                PdfPCell c = new PdfPCell();
                c.setBorderColor(VERDE_CLARO);
                c.setPadding(8);
                c.addElement(new Paragraph(String.valueOf(fila[1]), FontFactory.getFont(FontFactory.HELVETICA_BOLD, 16, VERDE)));
                c.addElement(new Paragraph(t(String.valueOf(fila[0])), chico));
                resumen.addCell(c);
            }
            doc.add(resumen);

            // Gráficos
            for (Serie s : r.getSeries()) {
                Paragraph h = new Paragraph(s.titulo(), seccion);
                h.setSpacingBefore(6);
                h.setKeepTogether(true);
                doc.add(h);
                if (s.descripcion() != null) doc.add(new Paragraph(s.descripcion(), chico));
                if (s.datos().isEmpty()) {
                    Paragraph v = new Paragraph(t("Sin datos todavía."), normal);
                    v.setSpacingAfter(12);
                    doc.add(v);
                    continue;
                }
                double max = s.datos().stream().mapToDouble(Dato::valor).max().orElse(1);
                PdfPTable tabla = new PdfPTable(new float[]{3.2f, 5.5f, 1.3f});
                tabla.setWidthPercentage(100);
                tabla.setSpacingBefore(6);
                tabla.setSpacingAfter(14);
                tabla.setKeepTogether(s.datos().size() <= 15);
                for (Dato d : s.datos()) {
                    PdfPCell etiqueta = new PdfPCell(new Phrase(d.etiqueta(), normal));
                    etiqueta.setBorder(Rectangle.NO_BORDER);
                    etiqueta.setPadding(4);
                    tabla.addCell(etiqueta);

                    PdfPCell barra = new PdfPCell(new Phrase(" "));
                    barra.setBorder(Rectangle.NO_BORDER);
                    barra.setFixedHeight(18);
                    barra.setCellEvent(new Barra(max <= 0 ? 0 : d.valor() / max));
                    tabla.addCell(barra);

                    PdfPCell valor = new PdfPCell(new Phrase(formatear(d.valor()), negrita));
                    valor.setBorder(Rectangle.NO_BORDER);
                    valor.setHorizontalAlignment(Element.ALIGN_RIGHT);
                    valor.setPadding(4);
                    tabla.addCell(valor);
                }
                doc.add(tabla);
            }

            doc.close();
            return out.toByteArray();
        } catch (Exception e) {
            throw new RuntimeException("Error generando el PDF de reportes: " + e.getMessage(), e);
        }
    }

    /** Dibuja dentro de la celda una barra horizontal proporcional al valor. */
    private record Barra(double proporcion) implements PdfPCellEvent {
        @Override
        public void cellLayout(PdfPCell cell, Rectangle pos, PdfContentByte[] canvases) {
            PdfContentByte cb = canvases[PdfPTable.BACKGROUNDCANVAS];
            float alto = pos.getHeight() - 6;
            float ancho = pos.getWidth() - 4;
            cb.saveState();
            cb.setColorFill(VERDE_CLARO);
            cb.rectangle(pos.getLeft() + 2, pos.getBottom() + 3, ancho, alto);
            cb.fill();
            cb.setColorFill(VERDE);
            cb.rectangle(pos.getLeft() + 2, pos.getBottom() + 3, (float) Math.max(2, ancho * proporcion), alto);
            cb.fill();
            cb.restoreState();
        }
    }

    // ---------- portugués ----------

    private static final Map<String, String> PT = Map.ofEntries(
            Map.entry("SafeBite - Reporte de estadísticas", "SafeBite - Relatório de estatísticas"),
            Map.entry("Generado el", "Gerado em"),
            Map.entry("Resumen", "Resumo"),
            Map.entry("Sin datos todavía.", "Ainda sem dados."),
            Map.entry("Usuarios", "Usuários"), Map.entry("Usuarios activos", "Usuários ativos"),
            Map.entry("Restaurantes", "Restaurantes"), Map.entry("Reseñas publicadas", "Avaliações publicadas"),
            Map.entry("Recetas publicadas", "Receitas publicadas"), Map.entry("Productos", "Produtos"),
            Map.entry("Noticias", "Notícias"), Map.entry("Alertas pendientes", "Alertas pendentes"),
            Map.entry("Productos por revisar", "Produtos para revisar"), Map.entry("Recetas por aprobar", "Receitas para aprovar"),
            Map.entry("Reseñas por aprobar", "Avaliações para aprovar"), Map.entry("Pedidos de contraseña", "Pedidos de senha"),
            Map.entry("Usuarios nuevos por mes", "Novos usuários por mês"),
            Map.entry("Registros de los últimos 6 meses", "Cadastros dos últimos 6 meses"),
            Map.entry("usuarios", "usuários"), Map.entry("productos", "produtos"), Map.entry("recetas", "receitas"),
            Map.entry("estrellas", "estrelas"), Map.entry("reseñas", "avaliações"), Map.entry("alertas", "alertas"),
            Map.entry("noticias", "notícias"), Map.entry("consultas", "consultas"),
            Map.entry("Usuarios por intolerancia", "Usuários por intolerância"),
            Map.entry("Cuántas personas declararon cada restricción", "Quantas pessoas declararam cada restrição"),
            Map.entry("Usuarios por país", "Usuários por país"), Map.entry("Sin indicar", "Não informado"),
            Map.entry("Uruguay", "Uruguai"), Map.entry("Paraguay", "Paraguai"), Map.entry("Perú", "Peru"),
            Map.entry("Colombia", "Colômbia"), Map.entry("Ecuador", "Equador"), Map.entry("España", "Espanha"),
            Map.entry("Bolivia", "Bolívia"),
            Map.entry("Productos por origen", "Produtos por origem"),
            Map.entry("Aportados por usuarios", "Enviados por usuários"), Map.entry("Cargados por el admin", "Cadastrados pelo admin"),
            Map.entry("Recetas publicadas por origen", "Receitas publicadas por origem"),
            Map.entry("Comunidad", "Comunidade"), Map.entry("Equipo SafeBite", "Equipe SafeBite"),
            Map.entry("Restaurantes mejor puntuados", "Restaurantes mais bem avaliados"),
            Map.entry("Promedio de estrellas (reseñas aprobadas)", "Média de estrelas (avaliações aprovadas)"),
            Map.entry("Reseñas por estado", "Avaliações por status"),
            Map.entry("Pendientes", "Pendentes"), Map.entry("Rechazadas", "Recusadas"), Map.entry("Aprobadas", "Aprovadas"),
            Map.entry("Alertas por estado", "Alertas por status"), Map.entry("Aceptadas", "Aceitas"), Map.entry("Denegadas", "Recusadas"),
            Map.entry("Alertas por tipo", "Alertas por tipo"), Map.entry("Comentarios", "Comentários"),
            Map.entry("Noticias por país", "Notícias por país"), Map.entry("Cargadas a mano", "Cadastradas manualmente"),
            Map.entry("Consultas de IA por mes", "Consultas de IA por mês"),
            Map.entry("Lectura de paquetes y traducciones (Claude y Gemini)", "Leitura de embalagens e traduções (Claude e Gemini)"),
            Map.entry("Trigo", "Trigo"), Map.entry("Centeno", "Centeio"), Map.entry("Cebada", "Cevada"), Map.entry("Avena", "Aveia"),
            Map.entry("Crustáceos", "Crustáceos"), Map.entry("Huevos", "Ovos"), Map.entry("Pescados", "Peixes"),
            Map.entry("Maní", "Amendoim"), Map.entry("Soja", "Soja"), Map.entry("Leche", "Leite"), Map.entry("Almendra", "Amêndoa"),
            Map.entry("Avellanas", "Avelãs"), Map.entry("Castaña de cajú", "Castanha de caju"),
            Map.entry("Castaña de Pará", "Castanha-do-pará"), Map.entry("Macadamias", "Macadâmias"), Map.entry("Nueces", "Nozes"),
            Map.entry("Pecanas", "Pecãs"), Map.entry("Pistachos", "Pistaches"), Map.entry("Piñones", "Pinhões"),
            Map.entry("Castañas", "Castanhas"), Map.entry("Látex natural", "Látex natural"));

    private static final Map<String, String> MESES_PT = Map.ofEntries(
            Map.entry("Ene", "Jan"), Map.entry("Feb", "Fev"), Map.entry("Mar", "Mar"), Map.entry("Abr", "Abr"),
            Map.entry("May", "Mai"), Map.entry("Jun", "Jun"), Map.entry("Jul", "Jul"), Map.entry("Ago", "Ago"),
            Map.entry("Sep", "Set"), Map.entry("Oct", "Out"), Map.entry("Nov", "Nov"), Map.entry("Dic", "Dez"));

    /** Texto en el idioma pedido (portugués si la app lo pidió). */
    private String t(String es) {
        if (es == null || !TraduccionRecetaService.pidePortugues()) return es;
        String fijo = PT.get(es);
        if (fijo != null) return fijo;
        java.util.regex.Matcher m = java.util.regex.Pattern.compile("^(\\p{L}{3}) (\\d{2})$").matcher(es);
        if (m.matches() && MESES_PT.containsKey(m.group(1))) return MESES_PT.get(m.group(1)) + " " + m.group(2);
        // Intolerancias agregadas por el admin u otros textos: traducción con IA (queda guardada).
        return traduccion.traducirUno("pt", es);
    }

    // ---------- utilidades ----------

    private static String formatear(double v) {
        return v == Math.rint(v) ? String.valueOf((long) v) : String.format(Locale.ROOT, "%.1f", v);
    }

    private static String texto(String s, String porDefecto) {
        return s == null || s.isBlank() ? porDefecto : s.trim();
    }

    private static <T> List<Dato> contar(Collection<T> items, Function<T, String> clave) {
        Map<String, Long> m = items.stream().collect(Collectors.groupingBy(clave, Collectors.counting()));
        return ordenados(m, Function.identity(), 0);
    }

    private static List<Dato> ordenados(Map<String, Long> m, Function<String, String> nombre, int limite) {
        var flujo = m.entrySet().stream()
                .sorted(Map.Entry.<String, Long>comparingByValue().reversed())
                .map(e -> new Dato(nombre.apply(e.getKey()), e.getValue()));
        return (limite > 0 ? flujo.limit(limite) : flujo).toList();
    }

    private static <T> List<Dato> porMes(Collection<T> items, Function<T, LocalDateTime> fecha, int meses) {
        YearMonth actual = YearMonth.now();
        Map<YearMonth, Long> cuenta = new HashMap<>();
        for (T i : items) {
            LocalDateTime f = fecha.apply(i);
            if (f != null) cuenta.merge(YearMonth.from(f), 1L, Long::sum);
        }
        List<Dato> datos = new ArrayList<>();
        for (int k = meses - 1; k >= 0; k--) {
            YearMonth ym = actual.minusMonths(k);
            datos.add(new Dato(MESES[ym.getMonthValue() - 1] + " " + (ym.getYear() % 100), cuenta.getOrDefault(ym, 0L)));
        }
        return datos;
    }
}

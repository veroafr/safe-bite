package com.safebite.backend.model;

import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * Codigos de las intolerancias / alergenos "de fabrica".
 *
 * Antes era un enum cerrado (GLUTEN, LACTOSA, FRUTOS_SECOS, MARISCOS). Ahora
 * las intolerancias viven en la tabla {@code intolerancias} y el administrador
 * puede agregar nuevas, asi que en todo el sistema se manejan como codigos
 * String. Esta clase solo define los codigos predefinidos (lista de los
 * principales alimentos que causan alergias alimentarias, Anexo III - RDC
 * ANVISA 26/2015), con los cereales separados uno por uno porque una persona
 * puede tener intolerancia a uno y no a otro.
 */
public final class TipoIntolerancia {

    private TipoIntolerancia() {}

    // Cereales (cada uno por separado)
    public static final String TRIGO = "TRIGO";
    public static final String CENTENO = "CENTENO";
    public static final String CEBADA = "CEBADA";
    public static final String AVENA = "AVENA";
    // Resto de la lista
    public static final String CRUSTACEOS = "CRUSTACEOS";
    public static final String HUEVO = "HUEVO";
    public static final String PESCADO = "PESCADO";
    public static final String MANI = "MANI";
    public static final String SOJA = "SOJA";
    public static final String LECHE = "LECHE";
    public static final String ALMENDRA = "ALMENDRA";
    public static final String AVELLANA = "AVELLANA";
    public static final String CASTANA_CAJU = "CASTANA_CAJU";
    public static final String CASTANA_PARA = "CASTANA_PARA";
    public static final String MACADAMIA = "MACADAMIA";
    public static final String NUEZ = "NUEZ";
    public static final String PECAN = "PECAN";
    public static final String PISTACHO = "PISTACHO";
    public static final String PINON = "PINON";
    public static final String CASTANA = "CASTANA";
    public static final String LATEX = "LATEX";

    /** Datos para sembrar la tabla la primera vez. */
    public record Predefinida(String codigo, String nombre, String nombreCientifico, String descripcion,
                              String palabrasClave) {}

    /**
     * palabrasClave: terminos (es / pt / en) separados por coma que el analizador
     * de texto busca en listas de ingredientes. Se comparan como palabras
     * completas (se aceptan plurales en -s / -es), sin acentos ni mayusculas.
     */
    public static final List<Predefinida> PREDEFINIDAS = List.of(
            new Predefinida(TRIGO, "Trigo", "Triticum spp.",
                    "Trigo y sus estirpes hibridizadas (incluye espelta, kamut, triticale).",
                    "trigo,wheat,harina de trigo,farinha de trigo,salvado de trigo,germen de trigo,semola,semolina,espelta,kamut,triticale,seitan,bulgur,cuscus,couscous,gluten"),
            new Predefinida(CENTENO, "Centeno", "Secale cereale",
                    "Centeno y sus estirpes hibridizadas (incluye triticale).",
                    "centeno,centeio,rye,triticale,gluten"),
            new Predefinida(CEBADA, "Cebada", "Hordeum vulgare",
                    "Cebada y sus estirpes hibridizadas. Incluye malta y extracto de malta.",
                    "cebada,cevada,barley,malta,malte,extracto de malta,extrato de malte,gluten"),
            new Predefinida(AVENA, "Avena", "Avena sativa",
                    "Avena y sus estirpes hibridizadas.",
                    "avena,aveia,oat,oats,gluten"),
            new Predefinida(CRUSTACEOS, "Crustáceos", null,
                    "Camarones, langostinos, langostas, cangrejos, etc.",
                    "crustaceo,crustaceos,camaron,camarao,langostino,langosta,lagosta,cangrejo,caranguejo,gamba,krill,siri,jaiba,shrimp,prawn,lobster,crab,marisco,mariscos,frutos do mar"),
            new Predefinida(HUEVO, "Huevos", null,
                    "Huevo y derivados (clara, yema, albúmina).",
                    "huevo,ovo,egg,clara de huevo,yema,gema de ovo,albumina,ovoalbumina,lisozima"),
            new Predefinida(PESCADO, "Pescados", null,
                    "Pescados y derivados.",
                    "pescado,peixe,fish,atun,atum,tuna,salmon,salmao,merluza,sardina,sardinha,bacalao,bacalhau,anchoa,anchova,surimi,aceite de pescado,oleo de peixe"),
            new Predefinida(MANI, "Maní", "Arachis hypogaea",
                    "Maní / cacahuete (amendoim).",
                    "mani,cacahuete,cacahuate,amendoim,peanut,pasta de mani,manteca de mani"),
            new Predefinida(SOJA, "Soja", "Glycine max",
                    "Soja y derivados.",
                    "soja,soya,soy,lecitina de soja,proteina de soja,tofu,shoyu,edamame,miso"),
            new Predefinida(LECHE, "Leche", null,
                    "Leches de todas las especies de animales mamíferos y sus derivados.",
                    "leche,leite,milk,lactosa,lactose,lacteo,lacteos,manteca,mantequilla,manteiga,queso,queijo,crema de leche,creme de leite,nata,suero de leche,soro de leite,yogur,yogurt,iogurte,caseina,caseinato,whey,lactoalbumina,lactoglobulina,ghee,ricota,requeijao,dulce de leche,doce de leite"),
            new Predefinida(ALMENDRA, "Almendra", "Prunus dulcis (sin.: Prunus amygdalus, Amygdalus communis L.)",
                    "Almendra.",
                    "almendra,amendoa,almond,mazapan,marzipan"),
            new Predefinida(AVELLANA, "Avellanas", "Corylus spp.",
                    "Avellanas.",
                    "avellana,avela,hazelnut,gianduia"),
            new Predefinida(CASTANA_CAJU, "Castaña de cajú", "Anacardium occidentale",
                    "Castaña de cajú / anacardo.",
                    "castana de caju,castanha de caju,caju,anacardo,cashew,maranon"),
            new Predefinida(CASTANA_PARA, "Castaña de Pará", "Bertholletia excelsa",
                    "Castaña de Brasil o castaña de Pará.",
                    "castana de para,castana do para,castanha do para,castanha do brasil,castana de brasil,nuez de brasil,brazil nut"),
            new Predefinida(MACADAMIA, "Macadamias", "Macadamia spp.",
                    "Nueces de macadamia.",
                    "macadamia"),
            new Predefinida(NUEZ, "Nueces", "Juglans spp.",
                    "Nueces (nogal).",
                    "nuez,nueces,noz,nozes,walnut"),
            new Predefinida(PECAN, "Pecanas", "Carya spp.",
                    "Nueces pecán.",
                    "pecan,pecana,pacana,noz peca,nozes peca,nuez pecan"),
            new Predefinida(PISTACHO, "Pistachos", "Pistacia spp.",
                    "Pistachos.",
                    "pistacho,pistache,pistachio"),
            new Predefinida(PINON, "Piñones", "Pinus spp.",
                    "Piñones (pinoli).",
                    "pinon,pinoli,pine nut,pinhao"),
            new Predefinida(CASTANA, "Castañas", "Castanea spp.",
                    "Castañas (castaño europeo).",
                    "castana,castanha,chestnut"),
            new Predefinida(LATEX, "Látex natural", null,
                    "Látex natural (puede tener reacción cruzada con algunos alimentos).",
                    "latex")
    );

    /** Codigos del enum anterior -> codigos nuevos (para migrar datos existentes). */
    public static final Map<String, Set<String>> LEGADO = Map.of(
            "GLUTEN", Set.of(TRIGO, CENTENO, CEBADA, AVENA),
            "LACTOSA", Set.of(LECHE),
            "FRUTOS_SECOS", Set.of(MANI, ALMENDRA, AVELLANA, CASTANA_CAJU, CASTANA_PARA, MACADAMIA,
                    NUEZ, PECAN, PISTACHO, PINON, CASTANA),
            "MARISCOS", Set.of(CRUSTACEOS)
    );

    /** Grupos usados por el catalogo de alimentos (familias de productos y sellos). */
    public static final Set<String> GRUPO_GLUTEN = Set.of(TRIGO, CENTENO, CEBADA, AVENA);
    public static final Set<String> GRUPO_FRUTOS_SECOS = LEGADO.get("FRUTOS_SECOS");
}

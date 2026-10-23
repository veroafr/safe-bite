package com.safebite.backend.service;

import com.safebite.backend.model.TipoIntolerancia;
import org.springframework.stereotype.Component;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

/**
 * Conocimiento de "que alimentos suelen llevar cada alergeno" y "con que se
 * reemplazan" (versiones sin TACC, sin lactosa, de arroz, de maiz...). Sirve
 * de respaldo cuando la IA no esta disponible y de pista para la IA.
 *
 * "variable" = alimentos cuya receta cambia segun marca o lote (o que pueden
 * contaminarse en la fabrica): ahi siempre se avisa que hay que revisar el envase.
 */
@Component
public class CatalogoAlimentos {

    public record Familia(String nombre, Set<String> claves, List<String> es, List<String> pt, boolean variable) {}

    /** claves separadas por coma; "stem*" = palabra que empieza con stem; es/pt = terminos separados por coma. */
    private static Familia f(String nombre, boolean variable, String claves, String es, String pt) {
        return new Familia(nombre, new HashSet<>(Arrays.asList(sinAcentos(claves).split(","))),
                Arrays.asList(es.split(",")), Arrays.asList(pt.split(",")), variable);
    }

    private static final Map<TipoIntolerancia, List<Familia>> FAMILIAS = Map.of(
            TipoIntolerancia.GLUTEN, List.of(
                    // Basicos
                    f("Pan y tostadas", false, "pan,panes,pancito,tostad*,pao,torrada*,sandwich*,lactal",
                            "pan sin tacc,tostadas de arroz", "pão sem glúten,torradas de arroz"),
                    f("Galletitas y panificados dulces", false, "galleta*,galletita*,cracker*,biscoito*,bizcoch*,factura*,medialuna*,budin*,muffin*,torta*,bolo*,masita*,cookie*",
                            "galletitas sin tacc,galletitas de arroz", "biscoitos sem glúten,biscoitos de arroz"),
                    f("Pastas", false, "pasta*,fideo*,tallarin*,espagueti*,spaghetti,macarron*,macarrao,noqui*,ñoqui*,nhoque*,lasana,lasagna,canelon*,ravioles,raviol*",
                            "fideos sin tacc,fideos de arroz", "macarrão sem glúten,macarrão de arroz"),
                    f("Harinas y rebozadores", false, "harina*,farinha*,premezcla*,rebozador*,semola,sêmola,polenta",
                            "harina sin tacc,harina de arroz", "farinha sem glúten,farinha de arroz"),
                    f("Cereales y avena", true, "cereal*,granola,avena,aveia,muesli,barra*,copos",
                            "cereales sin gluten,avena sin gluten", "cereais sem glúten,aveia sem glúten"),
                    // Prontos
                    f("Masas y tapas", false, "pizza*,empanada*,tapa*,tarta*,masa*,pastel*,wrap*,tortilla*,taco*",
                            "tapas de empanadas sin tacc,pizza sin tacc", "massa de pizza sem glúten,pizza sem glúten"),
                    f("Empanados y congelados", true, "milanesa*,nugget*,empanado*,empanizado*,rebozado*,croqueta*,hamburguesa*,medallon*,bastoncito*,congelad*",
                            "milanesas sin tacc,nuggets sin gluten", "empanados sem glúten,nuggets sem glúten"),
                    // Con gluten escondido segun marca
                    f("Salsas, caldos y sopas", true, "salsa*,aderezo*,soja,shoyu,caldo*,sopa*,mayonesa,mostaza,ketchup,condimento*,especia*,adobo*,molho*,tempero*",
                            "salsa de soja sin gluten,caldo sin gluten", "molho shoyu sem glúten,caldo sem glúten"),
                    f("Fiambres y embutidos", true, "salchicha*,jamon,mortadela,chorizo*,fiambre*,embutido*,salame,linguica,presunto,paleta,morcilla",
                            "salchichas sin gluten,jamón sin gluten", "salsicha sem glúten,presunto sem glúten"),
                    f("Cerveza y malta", false, "cerveza*,cerveja,malta",
                            "cerveza sin gluten", "cerveja sem glúten"),
                    f("Snacks y golosinas", true, "snack*,papas,chizito*,palito*,chocolate*,alfajor*,golosina*,caramelo*,helado*,postre*,sorvete*,chiclet*",
                            "snacks de maíz sin gluten,alfajores sin tacc", "snacks sem glúten,chocolate sem glúten")
            ),
            TipoIntolerancia.LACTOSA, List.of(
                    f("Leche", false, "leche*,leite*,bebida*",
                            "leche sin lactosa,bebida vegetal de arroz", "leite sem lactose,bebida vegetal de arroz"),
                    f("Yogur y postres lacteos", false, "yogur*,yogurt*,iogurte*,flan*,natilla*,postre*,pudin*",
                            "yogur sin lactosa,yogur vegetal", "iogurte sem lactose,iogurte vegetal"),
                    f("Quesos", false, "queso*,muzzarella,mozzarella,ricota,ricotta,untable,queijo*,cremoso,requeson,requeijao",
                            "queso sin lactosa,queso vegetal", "queijo sem lactose,queijo vegetal"),
                    f("Manteca y cremas", false, "manteca*,mantequilla,crema*,nata,manteiga*,creme*,dulce",
                            "manteca sin lactosa,crema sin lactosa", "manteiga sem lactose,creme de leite sem lactose"),
                    f("Helados y chocolates", true, "helado*,chocolate*,sorvete*,alfajor*,golosina*",
                            "helado sin lactosa,chocolate sin leche", "sorvete sem lactose,chocolate sem leite"),
                    f("Panificados", true, "pan,panes,galleta*,galletita*,bizcoch*,factura*,medialuna*,torta*,tostad*,biscoito*",
                            "pan sin lactosa,galletitas veganas", "pão sem lactose,biscoitos veganos")
            ),
            TipoIntolerancia.FRUTOS_SECOS, List.of(
                    f("Mani y pastas untables", true, "mani,cacahuete*,amendoim,pasta*,untable*,crema*",
                            "pasta de semillas de girasol,untable sin frutos secos", "pasta de sementes de girassol"),
                    f("Chocolates, barras y golosinas", true, "chocolate*,barra*,granola,turron*,alfajor*,golosina*,helado*,bombon*,cereal*",
                            "chocolate sin frutos secos,barras de cereal sin frutos secos", "chocolate sem castanhas,barra de cereal sem castanhas"),
                    f("Bebidas vegetales", false, "almendra*,bebida*,leche*",
                            "bebida vegetal de arroz,bebida vegetal de avena", "bebida vegetal de arroz,bebida vegetal de aveia")
            ),
            TipoIntolerancia.MARISCOS, List.of(
                    f("Pescados y mariscos", true, "surimi,camaron*,langostino*,marisco*,pescado*,atun,conserva*,paella,ostra*,calamar*,camarao,lula",
                            "atún en conserva,sardinas en conserva", "atum em conserva,sardinha em conserva"),
                    f("Caldos y salsas", true, "caldo*,salsa*,sopa*,snack*",
                            "caldo de verduras,salsa de tomate", "caldo de legumes,molho de tomate")
            )
    );

    /** Primera familia del alergeno que coincide con el texto (nombre/categoria del producto). */
    public Optional<Familia> buscar(TipoIntolerancia alergeno, String texto) {
        Set<String> palabras = palabras(texto);
        for (Familia fam : FAMILIAS.getOrDefault(alergeno, List.of())) {
            for (String clave : fam.claves()) {
                if (coincide(clave, palabras)) return Optional.of(fam);
            }
        }
        return Optional.empty();
    }

    /** true si alguna familia que coincide cambia segun marca/lote (hay que revisar el envase). */
    public boolean esVariable(Set<TipoIntolerancia> conflicto, String texto) {
        for (TipoIntolerancia t : conflicto) {
            if (buscar(t, texto).map(Familia::variable).orElse(false)) return true;
        }
        return false;
    }

    /** Familias coincidentes (una por alergeno en conflicto). */
    public List<Familia> familias(Set<TipoIntolerancia> conflicto, String texto) {
        List<Familia> r = new ArrayList<>();
        for (TipoIntolerancia t : conflicto) buscar(t, texto).ifPresent(r::add);
        return r;
    }

    private boolean coincide(String clave, Set<String> palabras) {
        if (clave.endsWith("*")) {
            String stem = clave.substring(0, clave.length() - 1);
            return palabras.stream().anyMatch(p -> p.startsWith(stem));
        }
        return palabras.contains(clave);
    }

    private static String sinAcentos(String t) {
        // la ñ queda como n tras quitar la marca combinante
        return Normalizer.normalize(t, Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase();
    }

    private Set<String> palabras(String texto) {
        Set<String> r = new HashSet<>();
        if (texto == null) return r;
        String n = Normalizer.normalize(texto, Normalizer.Form.NFD).replaceAll("\\p{M}", "").toLowerCase();
        for (String p : n.split("[^a-z]+")) if (!p.isEmpty()) r.add(p);
        return r;
    }
}

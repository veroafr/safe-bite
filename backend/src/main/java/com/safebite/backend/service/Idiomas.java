package com.safebite.backend.service;

import org.springframework.context.i18n.LocaleContextHolder;

import java.util.Locale;

/**
 * Idioma de la respuesta segun el encabezado Accept-Language que manda la app
 * ("es" o "pt"). Sirve para que los textos que arma el servidor y los que
 * escribe la IA salgan en el mismo idioma que esta usando la persona.
 */
public final class Idiomas {

    private Idiomas() {}

    /** true si la app esta en portugues. */
    public static boolean pt() {
        Locale l = LocaleContextHolder.getLocale();
        return l != null && "pt".equalsIgnoreCase(l.getLanguage());
    }

    /** Elige el texto segun el idioma de la app. */
    public static String t(String es, String pt) {
        return pt() ? pt : es;
    }

    /** Nombre del idioma para indicarselo a la IA en los prompts. */
    public static String paraIa() {
        return pt() ? "portugués de Brasil" : "español rioplatense (Uruguay)";
    }
}

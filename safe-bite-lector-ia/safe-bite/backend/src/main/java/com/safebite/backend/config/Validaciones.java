package com.safebite.backend.config;

/** Expresiones regulares compartidas por los DTOs (deben coincidir con las del frontend). */
public final class Validaciones {

    private Validaciones() {}

    /** usuario@dominio.ext (con al menos un punto en el dominio y extension de 2+ letras). */
    public static final String EMAIL = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\\.[A-Za-z0-9-]+)*\\.[A-Za-z]{2,}$";
    public static final String EMAIL_MENSAJE = "Ingresá un email válido (ejemplo: nombre@dominio.com)";

    /** Minimo 6 caracteres, al menos 1 mayuscula, 1 numero y 1 caracter especial. */
    public static final String PASSWORD = "^(?=.*[A-Z])(?=.*\\d)(?=.*[^A-Za-z0-9\\s]).{6,}$";
    public static final String PASSWORD_MENSAJE =
            "La contraseña debe tener al menos 6 caracteres, una mayúscula, un número y un carácter especial";
}

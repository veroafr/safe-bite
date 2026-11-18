package com.safebite.backend.service;

import com.safebite.backend.exception.BadRequestException;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.ImageOutputStream;
import java.awt.Color;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.util.Base64;

/**
 * Prepara las fotos de los restaurantes: la miniatura (cuadrada) y el banner
 * (rectangular, 2:1). La app ya manda la foto encuadrada por el
 * administrador; acá se asegura la proporción exacta (recortando al centro si
 * hiciera falta), se lleva al tamaño final y se guarda como JPEG liviano.
 */
public final class ImagenRestauranteUtil {

    public static final int MINIATURA_LADO = 400;
    public static final int BANNER_ANCHO = 1200;
    public static final int BANNER_ALTO = 600;

    private ImagenRestauranteUtil() {}

    /** Devuelve un data URL "data:image/jpeg;base64,..." de ancho×alto exactos. */
    public static String preparar(String imagen, int ancho, int alto) {
        BufferedImage original = leer(imagen);
        BufferedImage recortada = recortarAlCentro(original, (double) ancho / alto);

        // Fondo blanco: las fotos PNG con transparencia (logos) no quedan negras en JPEG.
        BufferedImage destino = new BufferedImage(ancho, alto, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = destino.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, ancho, alto);
        g.drawImage(recortada, 0, 0, ancho, alto, null);
        g.dispose();

        return "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(aJpeg(destino, 0.85f));
    }

    /** Reduce la imagen (sin recortar) para que su lado mayor no pase de maxLado. */
    public static String ajustar(String imagen, int maxLado) {
        BufferedImage original = leer(imagen);
        int w = original.getWidth();
        int h = original.getHeight();
        double escala = Math.min(1.0, (double) maxLado / Math.max(w, h));
        int ancho = Math.max(1, (int) Math.round(w * escala));
        int alto = Math.max(1, (int) Math.round(h * escala));
        BufferedImage destino = new BufferedImage(ancho, alto, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = destino.createGraphics();
        g.setRenderingHint(RenderingHints.KEY_INTERPOLATION, RenderingHints.VALUE_INTERPOLATION_BICUBIC);
        g.setRenderingHint(RenderingHints.KEY_RENDERING, RenderingHints.VALUE_RENDER_QUALITY);
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, ancho, alto);
        g.drawImage(original, 0, 0, ancho, alto, null);
        g.dispose();
        return "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(aJpeg(destino, 0.8f));
    }

    private static BufferedImage leer(String imagen) {
        String datos = imagen.trim();
        int coma = datos.indexOf(',');
        if (datos.startsWith("data:") && coma > 0) datos = datos.substring(coma + 1);
        try {
            byte[] bytes = Base64.getDecoder().decode(datos.replaceAll("\\s", ""));
            BufferedImage img = ImageIO.read(new ByteArrayInputStream(bytes));
            if (img == null) throw new BadRequestException("El formato de la imagen no es compatible. Usá JPG o PNG.");
            return img;
        } catch (IllegalArgumentException e) {
            throw new BadRequestException("La imagen no es válida.");
        } catch (java.io.IOException e) {
            throw new BadRequestException("No se pudo leer la imagen.");
        }
    }

    private static BufferedImage recortarAlCentro(BufferedImage img, double proporcion) {
        int w = img.getWidth();
        int h = img.getHeight();
        double actual = (double) w / h;
        if (Math.abs(actual - proporcion) < 0.01) return img;
        if (actual > proporcion) {
            int nuevoAncho = (int) Math.round(h * proporcion);
            return img.getSubimage((w - nuevoAncho) / 2, 0, nuevoAncho, h);
        }
        int nuevoAlto = (int) Math.round(w / proporcion);
        return img.getSubimage(0, (h - nuevoAlto) / 2, w, nuevoAlto);
    }

    private static byte[] aJpeg(BufferedImage img, float calidad) {
        try (ByteArrayOutputStream salida = new ByteArrayOutputStream()) {
            ImageWriter writer = ImageIO.getImageWritersByFormatName("jpeg").next();
            ImageWriteParam param = writer.getDefaultWriteParam();
            param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
            param.setCompressionQuality(calidad);
            try (ImageOutputStream ios = ImageIO.createImageOutputStream(salida)) {
                writer.setOutput(ios);
                writer.write(null, new IIOImage(img, null, null), param);
            } finally {
                writer.dispose();
            }
            return salida.toByteArray();
        } catch (java.io.IOException e) {
            throw new BadRequestException("No se pudo procesar la imagen.");
        }
    }
}

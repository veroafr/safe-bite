package com.safebite.backend.service;

import com.safebite.backend.dto.request.AportarProductoRequest;
import com.safebite.backend.dto.request.ProductoRequest;
import com.safebite.backend.dto.response.AnalisisIngredientesResponse;
import com.safebite.backend.dto.response.EscaneoResponse;
import com.safebite.backend.dto.response.ProductoResponse;
import com.safebite.backend.exception.BadRequestException;
import com.safebite.backend.exception.ResourceNotFoundException;
import com.safebite.backend.model.OrigenProducto;
import com.safebite.backend.model.Producto;
import com.safebite.backend.model.TipoIntolerancia;
import com.safebite.backend.model.Usuario;
import com.safebite.backend.repository.ProductoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class ProductoService {

    private final ProductoRepository productoRepository;
    private final OpenFoodFactsService openFoodFactsService;
    private final AlergenoTextAnalyzer alergenoTextAnalyzer;

    public List<ProductoResponse> buscarPorNombre(String nombre) {
        return productoRepository.findByNombreContainingIgnoreCase(nombre)
                .stream().map(ProductoResponse::desde).toList();
    }

    /**
     * Cadena de busqueda para un codigo de barras:
     * 1) Base propia.
     * 2) Open Food Facts, como respaldo.
     * 3) Si no aparece en ningun lado, se informa como no encontrado -> el
     *    frontend ofrece cargarlo a mano (aportar()).
     * Si aparece pero con datos insuficientes (sin ingredientes/alergenos),
     * el frontend ofrece completarlo (completarDatos()).
     */
    @Transactional
    public EscaneoResponse escanearPorEan(String codigoEan, Usuario usuario) {
        Producto producto = productoRepository.findByCodigoEan(codigoEan)
                .orElseGet(() -> buscarYCachearDesdeOpenFoodFacts(codigoEan)
                        .orElseThrow(() -> new ResourceNotFoundException(
                                "No se encontro ningun producto con el codigo " + codigoEan)));
        return evaluarParaUsuario(producto, usuario);
    }

    private java.util.Optional<Producto> buscarYCachearDesdeOpenFoodFacts(String codigoEan) {
        return openFoodFactsService.buscarPorEan(codigoEan).map(externo -> {
            Producto nuevo = Producto.builder()
                    .nombre(externo.nombre())
                    .marca(externo.marca())
                    .codigoEan(codigoEan)
                    .imagenUrl(externo.imagenUrl())
                    .ingredientes(externo.ingredientes())
                    .alergenos(externo.alergenos())
                    .origen(OrigenProducto.OPEN_FOOD_FACTS)
                    .verificado(true)
                    .build();
            return productoRepository.save(nuevo);
        });
    }

    public EscaneoResponse escanearPorOcr(String textoDetectado, Usuario usuario) {
        List<Producto> coincidencias = productoRepository.findByNombreContainingIgnoreCase(textoDetectado.trim());
        if (coincidencias.isEmpty()) {
            throw new ResourceNotFoundException("No se pudo reconocer el producto a partir del texto detectado");
        }
        return evaluarParaUsuario(coincidencias.get(0), usuario);
    }

    public AnalisisIngredientesResponse analizarIngredientes(String texto, Usuario usuario) {
        Set<TipoIntolerancia> detectados = alergenoTextAnalyzer.detectar(texto);
        Set<TipoIntolerancia> intoleranciasUsuario = usuario != null ? usuario.getIntolerancias() : Set.of();
        Set<TipoIntolerancia> enConflicto = new HashSet<>(detectados);
        enConflicto.retainAll(intoleranciasUsuario);

        boolean seguro = enConflicto.isEmpty();

        return AnalisisIngredientesResponse.builder()
                .seguro(seguro)
                .alergenosEncontrados(detectados)
                .mensaje(seguro
                        ? "No detectamos alergenos que coincidan con tus intolerancias en este texto. De todas formas, revisa el empaque si tenes dudas."
                        : "Atencion: detectamos en los ingredientes alergenos que coinciden con tus intolerancias.")
                .textoAnalizado(texto)
                .build();
    }

    /**
     * Un usuario carga a mano un producto que no aparecio en el escaneo.
     * Queda sin verificar hasta que un admin lo revise.
     */
    @Transactional
    public ProductoResponse aportar(AportarProductoRequest request, Usuario usuario) {
        if (request.getNombre() == null || request.getNombre().isBlank()) {
            throw new BadRequestException("El nombre del producto es obligatorio");
        }
        if (productoRepository.findByCodigoEan(request.getCodigoEan()).isPresent()) {
            throw new BadRequestException("Ya existe un producto cargado con ese codigo de barras");
        }

        Producto producto = Producto.builder()
                .nombre(request.getNombre())
                .marca(request.getMarca())
                .codigoEan(request.getCodigoEan())
                .imagenUrl(request.getImagenUrl())
                .ingredientes(request.getIngredientes() != null ? request.getIngredientes() : List.of())
                .alergenos(request.getAlergenos() != null ? request.getAlergenos() : Set.of())
                .origen(OrigenProducto.USUARIO)
                .verificado(false)
                .aportadoPorEmail(usuario != null ? usuario.getEmail() : null)
                .fotoFrontalBase64(request.getFotoFrontalBase64())
                .fotoComposicionBase64(request.getFotoComposicionBase64())
                .fotoNutricionalBase64(request.getFotoNutricionalBase64())
                .build();

        return ProductoResponse.desde(productoRepository.save(producto));
    }

    public List<ProductoResponse> listarPendientes() {
        return productoRepository.findByVerificadoFalseOrderByFechaCreacionDesc()
                .stream().map(ProductoResponse::desde).toList();
    }

    /**
     * Un usuario completa los datos de un producto que ya existe (por ej.
     * vino de Open Food Facts con ingredientes vacios, o con fotos
     * faltantes). No pisa un producto ya verificado con datos completos:
     * si ya tenia ingredientes cargados y esta verificado, rechaza el
     * pedido para evitar que alguien sobreescriba informacion correcta.
     */
    @Transactional
    public ProductoResponse completarDatos(Long id, AportarProductoRequest request, Usuario usuario) {
        Producto producto = buscarEntidad(id);

        boolean yaTeniaDatos = !producto.getIngredientes().isEmpty() || !producto.getAlergenos().isEmpty();
        if (yaTeniaDatos && producto.isVerificado()) {
            throw new BadRequestException("Este producto ya tiene datos verificados, no se puede sobreescribir");
        }

        if (request.getNombre() != null && !request.getNombre().isBlank()) {
            producto.setNombre(request.getNombre());
        }
        if (request.getMarca() != null && !request.getMarca().isBlank()) {
            producto.setMarca(request.getMarca());
        }
        if (request.getImagenUrl() != null && !request.getImagenUrl().isBlank()) {
            producto.setImagenUrl(request.getImagenUrl());
        }
        if (request.getIngredientes() != null && !request.getIngredientes().isEmpty()) {
            producto.setIngredientes(request.getIngredientes());
        }
        if (request.getAlergenos() != null && !request.getAlergenos().isEmpty()) {
            producto.setAlergenos(request.getAlergenos());
        }
        if (request.getFotoFrontalBase64() != null) {
            producto.setFotoFrontalBase64(request.getFotoFrontalBase64());
        }
        if (request.getFotoComposicionBase64() != null) {
            producto.setFotoComposicionBase64(request.getFotoComposicionBase64());
        }
        if (request.getFotoNutricionalBase64() != null) {
            producto.setFotoNutricionalBase64(request.getFotoNutricionalBase64());
        }

        producto.setOrigen(OrigenProducto.USUARIO);
        producto.setVerificado(false);
        producto.setAportadoPorEmail(usuario != null ? usuario.getEmail() : producto.getAportadoPorEmail());

        return ProductoResponse.desde(productoRepository.save(producto));
    }

    private EscaneoResponse evaluarParaUsuario(Producto producto, Usuario usuario) {
        Set<TipoIntolerancia> intoleranciasUsuario = usuario != null ? usuario.getIntolerancias() : Set.of();
        Set<TipoIntolerancia> enConflicto = new HashSet<>(producto.getAlergenos());
        enConflicto.retainAll(intoleranciasUsuario);

        boolean datosSuficientes = !producto.getIngredientes().isEmpty() || !producto.getAlergenos().isEmpty();
        boolean seguro = datosSuficientes && enConflicto.isEmpty();

        String mensaje;
        if (!producto.isVerificado()) {
            mensaje = "Este producto fue cargado por otro usuario y todavia no fue revisado por un administrador. Usalo con precaucion.";
        } else if (!datosSuficientes) {
            mensaje = "No tenemos información suficiente sobre los ingredientes de este producto. Revisá el empaque antes de consumirlo.";
        } else if (seguro) {
            mensaje = "Este producto es seguro segun tus intolerancias registradas.";
        } else {
            mensaje = "Atencion: este producto contiene alergenos que coinciden con tus intolerancias.";
        }

        return EscaneoResponse.builder()
                .producto(ProductoResponse.desde(producto))
                .seguro(seguro && producto.isVerificado())
                .datosSuficientes(datosSuficientes)
                .alergenosEnConflicto(enConflicto)
                .mensaje(mensaje)
                .build();
    }

    public Producto buscarEntidad(Long id) {
        return productoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Producto no encontrado"));
    }

    @Transactional
    public ProductoResponse crear(ProductoRequest request) {
        Producto producto = Producto.builder()
                .nombre(request.getNombre())
                .marca(request.getMarca())
                .codigoEan(request.getCodigoEan())
                .imagenUrl(request.getImagenUrl())
                .ingredientes(request.getIngredientes())
                .alergenos(request.getAlergenos())
                .origen(OrigenProducto.ADMIN)
                .verificado(true)
                .fotoFrontalBase64(request.getFotoFrontalBase64())
                .fotoComposicionBase64(request.getFotoComposicionBase64())
                .fotoNutricionalBase64(request.getFotoNutricionalBase64())
                .build();
        return ProductoResponse.desde(productoRepository.save(producto));
    }

    @Transactional
    public ProductoResponse editar(Long id, ProductoRequest request) {
        Producto producto = buscarEntidad(id);
        producto.setNombre(request.getNombre());
        producto.setMarca(request.getMarca());
        producto.setCodigoEan(request.getCodigoEan());
        producto.setImagenUrl(request.getImagenUrl());
        if (request.getIngredientes() != null) producto.setIngredientes(request.getIngredientes());
        if (request.getAlergenos() != null) producto.setAlergenos(request.getAlergenos());
        if (request.getVerificado() != null) producto.setVerificado(request.getVerificado());
        if (request.getFotoFrontalBase64() != null) producto.setFotoFrontalBase64(request.getFotoFrontalBase64());
        if (request.getFotoComposicionBase64() != null) producto.setFotoComposicionBase64(request.getFotoComposicionBase64());
        if (request.getFotoNutricionalBase64() != null) producto.setFotoNutricionalBase64(request.getFotoNutricionalBase64());
        return ProductoResponse.desde(productoRepository.save(producto));
    }

    @Transactional
    public void eliminar(Long id) {
        if (!productoRepository.existsById(id)) {
            throw new ResourceNotFoundException("Producto no encontrado");
        }
        productoRepository.deleteById(id);
    }

    public List<ProductoResponse> listarTodos() {
        return productoRepository.findAll().stream().map(ProductoResponse::desde).toList();
    }
}

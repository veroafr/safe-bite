package com.safebite.backend.service;

import com.safebite.backend.dto.request.ProductoRequest;
import com.safebite.backend.dto.response.AnalisisIngredientesResponse;
import com.safebite.backend.dto.response.EscaneoResponse;
import com.safebite.backend.dto.response.ProductoResponse;
import com.safebite.backend.exception.ResourceNotFoundException;
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

    private EscaneoResponse evaluarParaUsuario(Producto producto, Usuario usuario) {
        Set<TipoIntolerancia> intoleranciasUsuario = usuario != null ? usuario.getIntolerancias() : Set.of();
        Set<TipoIntolerancia> enConflicto = new HashSet<>(producto.getAlergenos());
        enConflicto.retainAll(intoleranciasUsuario);

        boolean datosSuficientes = !producto.getIngredientes().isEmpty() || !producto.getAlergenos().isEmpty();
        boolean seguro = datosSuficientes && enConflicto.isEmpty();

        String mensaje;
        if (!datosSuficientes) {
            mensaje = "No tenemos información suficiente sobre los ingredientes de este producto. Revisá el empaque antes de consumirlo.";
        } else if (seguro) {
            mensaje = "Este producto es seguro segun tus intolerancias registradas.";
        } else {
            mensaje = "Atencion: este producto contiene alergenos que coinciden con tus intolerancias.";
        }

        return EscaneoResponse.builder()
                .producto(ProductoResponse.desde(producto))
                .seguro(seguro)
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
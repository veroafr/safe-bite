package com.safebite.backend.service;

import com.safebite.backend.model.UsoIa;
import com.safebite.backend.repository.UsoIaRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Lleva la cuenta del gasto estimado en Claude (guardado en la base, asi no
 * se pierde cuando Render duerme o reinicia el servicio) y corta el uso de
 * Claude al llegar al presupuesto, para no gastar mas de lo previsto.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class IaGastoService {

    private final UsoIaRepository repository;

    @Value("${safebite.ia.presupuesto-usd:5.0}")
    private double presupuestoUsd;

    public void registrar(String proveedor, String operacion, int tokensEntrada, int tokensSalida, double costoUsd) {
        try {
            repository.save(UsoIa.builder()
                    .proveedor(proveedor).operacion(operacion)
                    .tokensEntrada(tokensEntrada).tokensSalida(tokensSalida)
                    .costoUsd(costoUsd).build());
        } catch (Exception e) {
            // Nunca romper el escaneo por no poder registrar el gasto.
            log.warn("No se pudo registrar el uso de IA: {}", e.getMessage());
        }
    }

    public double gastoClaudeUsd() {
        try {
            return repository.gastoTotal("CLAUDE");
        } catch (Exception e) {
            log.warn("No se pudo leer el gasto de IA: {}", e.getMessage());
            return 0;
        }
    }

    /** true mientras no se haya agotado el presupuesto estimado. */
    public boolean hayPresupuesto() {
        return gastoClaudeUsd() < presupuestoUsd;
    }

    public Map<String, Object> resumen() {
        double gasto = gastoClaudeUsd();
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("presupuestoUsd", presupuestoUsd);
        r.put("gastoEstimadoClaudeUsd", Math.round(gasto * 10000.0) / 10000.0);
        r.put("restanteEstimadoUsd", Math.round(Math.max(0, presupuestoUsd - gasto) * 10000.0) / 10000.0);
        r.put("llamadasClaude", repository.countByProveedor("CLAUDE"));
        r.put("llamadasGemini", repository.countByProveedor("GEMINI"));
        r.put("nota", "Estimacion segun los tokens informados por la API; el saldo real esta en la Consola de Anthropic.");
        return r;
    }
}

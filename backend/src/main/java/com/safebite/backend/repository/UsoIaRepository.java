package com.safebite.backend.repository;

import com.safebite.backend.model.UsoIa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UsoIaRepository extends JpaRepository<UsoIa, Long> {

    @Query("select coalesce(sum(u.costoUsd), 0.0) from UsoIa u where u.proveedor = :proveedor")
    double gastoTotal(@org.springframework.data.repository.query.Param("proveedor") String proveedor);

    long countByProveedor(String proveedor);
}

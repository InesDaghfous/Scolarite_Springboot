package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;

@RepositoryRestResource
public interface DepartementRepository extends JpaRepository<Departement, Long> {

    // GET /departements/search/findByCodDept?codDept=TI
    Departement findByCodDept(@Param("codDept") String codDept);

    // GET /departements/search/findByNomDeptContaining?nom=Info
    List<Departement> findByNomDeptContaining(@Param("nom") String nom);
}


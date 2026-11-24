package org.isetn;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

import java.util.List;
import java.util.Optional;

@RepositoryRestResource
public interface ClasseRepository extends JpaRepository<Classe, Long> {

    // GET /classes/search/findByCodClass?codClass=DSI33
    Optional<Classe> findByCodClass(@Param("codClass") String codClass);

    // GET /classes/search/findByDepartementCodDept?codDept=TI
    List<Classe> findByDepartementCodDept(@Param("codDept") String codDept);

    // GET /classes/search/findByDepartementId?departementId=1
    List<Classe> findByDepartement_Id(@Param("departementId") Long departementId);
}

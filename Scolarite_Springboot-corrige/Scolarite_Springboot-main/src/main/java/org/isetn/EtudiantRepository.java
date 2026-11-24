package org.isetn;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface EtudiantRepository extends JpaRepository<Etudiant, Long> {

    // GET /etudiants/search/findByNomContains?nom=ali
    List<Etudiant> findByNomContains(@Param("nom") String nom);

    // GET /etudiants/search/findByNce?nce=DSI33001
    Optional<Etudiant> findByNce(@Param("nce") String nce);

    // GET /etudiants/search/findByClasseCodClass?codClass=DSI33&projection=p1
    List<Etudiant> findByClasseCodClass(@Param("codClass") String codClass);

    // GET /etudiants/search/findByClasseId?classeId=1&projection=p1
    List<Etudiant> findByClasse_Id(@Param("classeId") Long classeId);
}

package org.isetn;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface AbsenceRepository extends JpaRepository<Absence, Long> {

    // GET /absences/search/findByNce?nce=DSI33001
    // Cherche par le champ nce (String) directement dans la table
    List<Absence> findByNce(@Param("nce") String nce);

    // GET /absences/search/findByEtudiantNce?nce=DSI33001
    // Cherche par le champ nce de l'entité Etudiant liée
    List<Absence> findByEtudiantNce(@Param("nce") String nce);

    // GET /absences/search/findByEtudiant_Id?etudiantId=1
    List<Absence> findByEtudiant_Id(@Param("etudiantId") Long etudiantId);

   //classe il kol
    List<Absence> findByNceAndCodMatAndDateA(
        @Param("nce") String nce,
        @Param("codMat") String codMat,
        @Param("dateA") String dateA
    );

    
    List<Absence> findByCodMatAndDateA(
        @Param("codMat") String codMat,
        @Param("dateA") String dateA
    );
}

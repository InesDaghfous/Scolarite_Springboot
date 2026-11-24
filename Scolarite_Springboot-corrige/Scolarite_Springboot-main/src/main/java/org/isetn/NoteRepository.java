package org.isetn;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.repository.query.Param;
import org.springframework.data.rest.core.annotation.RepositoryRestResource;

@RepositoryRestResource
public interface NoteRepository extends JpaRepository<Note, Long> {

    // GET /notes/search/findByNce?nce=DSI33001
    List<Note> findByNce(@Param("nce") String nce);

    // GET /notes/search/findByNceAndCodMat?nce=DSI33001&codMat=AFCP
    List<Note> findByNceAndCodMat(@Param("nce") String nce, @Param("codMat") String codMat);
}

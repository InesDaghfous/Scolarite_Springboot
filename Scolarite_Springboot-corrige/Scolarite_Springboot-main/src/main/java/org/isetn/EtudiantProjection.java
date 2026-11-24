package org.isetn;

import java.util.Date;
import org.springframework.data.rest.core.config.Projection;

@Projection(name = "p1", types = { Etudiant.class })
public interface EtudiantProjection {
    Long getId();
    String getNce();
    String getNom();
    String getPrenom();
    Date getDateNais();
    String getLieuNais();
    Formation getFormation();
    Classe getClasse();
}

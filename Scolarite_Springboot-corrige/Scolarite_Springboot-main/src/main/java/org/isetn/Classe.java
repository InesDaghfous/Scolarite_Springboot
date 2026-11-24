package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnore;
import javax.persistence.*;
import java.util.List;

@Entity
public class Classe {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String codClass;
    private String nomClass;
    private int nbreEtud;

    @ManyToOne
    private Departement departement;

    @JsonIgnore
    @OneToMany(mappedBy = "classe")
    private List<Etudiant> etudiants;

    public Classe() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCodClass() { return codClass; }
    public void setCodClass(String codClass) { this.codClass = codClass; }

    public String getNomClass() { return nomClass; }
    public void setNomClass(String nomClass) { this.nomClass = nomClass; }

    public int getNbreEtud() { return nbreEtud; }
    public void setNbreEtud(int nbreEtud) { this.nbreEtud = nbreEtud; }

    public Departement getDepartement() { return departement; }
    public void setDepartement(Departement departement) { this.departement = departement; }

    public List<Etudiant> getEtudiants() { return etudiants; }
    public void setEtudiants(List<Etudiant> etudiants) { this.etudiants = etudiants; }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof Classe)) return false;
        Classe c = (Classe) o;
        return id != null && id.equals(c.id);
    }

    @Override
    public int hashCode() { return id != null ? id.hashCode() : 0; }
}

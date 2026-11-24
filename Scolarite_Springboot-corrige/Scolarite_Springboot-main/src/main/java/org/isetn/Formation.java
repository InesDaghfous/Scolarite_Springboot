package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnore;
import javax.persistence.*;
import java.util.List;

@Entity
public class Formation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String nom;
    private int duree;

    @JsonIgnore
    @OneToMany(mappedBy = "formation")
    private List<Etudiant> etudiants;

    public Formation() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public int getDuree() { return duree; }
    public void setDuree(int duree) { this.duree = duree; }

    public List<Etudiant> getEtudiants() { return etudiants; }
    public void setEtudiants(List<Etudiant> etudiants) { this.etudiants = etudiants; }
}

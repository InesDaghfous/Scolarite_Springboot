package org.isetn;

import javax.persistence.*;
import java.util.Date;

@Entity
public class Etudiant {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true)
    private String nce;

    private String nom;
    private String prenom;
    private Date dateNais;
    private String lieuNais;

    @ManyToOne
    private Formation formation;

    @ManyToOne
    private Classe classe;

    public Etudiant() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNce() { return nce; }
    public void setNce(String nce) { this.nce = nce; }

    public String getNom() { return nom; }
    public void setNom(String nom) { this.nom = nom; }

    public String getPrenom() { return prenom; }
    public void setPrenom(String prenom) { this.prenom = prenom; }

    public Date getDateNais() { return dateNais; }
    public void setDateNais(Date dateNais) { this.dateNais = dateNais; }

    public String getLieuNais() { return lieuNais; }
    public void setLieuNais(String lieuNais) { this.lieuNais = lieuNais; }

    public Formation getFormation() { return formation; }
    public void setFormation(Formation formation) { this.formation = formation; }

    public Classe getClasse() { return classe; }
    public void setClasse(Classe classe) { this.classe = classe; }
}

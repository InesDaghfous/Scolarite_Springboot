package org.isetn;

import javax.persistence.*;

@Entity
public class Absence {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String codMat;
    private String nce;
    private String dateA;
    private double nha;

    @ManyToOne
    @JoinColumn(name = "etudiant_id")
    private Etudiant etudiant;

    public Absence() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCodMat() { return codMat; }
    public void setCodMat(String codMat) { this.codMat = codMat; }

    public String getNce() { return nce; }
    public void setNce(String nce) { this.nce = nce; }

    public String getDateA() { return dateA; }
    public void setDateA(String dateA) { this.dateA = dateA; }

    public double getNha() { return nha; }
    public void setNha(double nha) { this.nha = nha; }

    public Etudiant getEtudiant() { return etudiant; }
    public void setEtudiant(Etudiant etudiant) { this.etudiant = etudiant; }
}

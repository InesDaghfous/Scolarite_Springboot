package org.isetn;

import javax.persistence.*;

@Entity
public class Note {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Numéro carte étudiant
    private String nce;

    // Code matière (ex: "AFCP", "SOA", "ALGO", "BD")
    private String codMat;

    // Nom complet de la matière
    private String nomMat;

    // Coefficient de la matière (ex: 1.0, 1.5, 2.0, 3.0)
    private double coef = 1.0;

    // Notes optionnelles (null si non applicable)
    private Double tp1;
    private Double tp2;
    private Double ds;
    private Double examen;

    public Note() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNce() { return nce; }
    public void setNce(String nce) { this.nce = nce; }

    public String getCodMat() { return codMat; }
    public void setCodMat(String codMat) { this.codMat = codMat; }

    public String getNomMat() { return nomMat; }
    public void setNomMat(String nomMat) { this.nomMat = nomMat; }

    public double getCoef() { return coef; }
    public void setCoef(double coef) { this.coef = coef; }

    public Double getTp1() { return tp1; }
    public void setTp1(Double tp1) { this.tp1 = tp1; }

    public Double getTp2() { return tp2; }
    public void setTp2(Double tp2) { this.tp2 = tp2; }

    public Double getDs() { return ds; }
    public void setDs(Double ds) { this.ds = ds; }

    public Double getExamen() { return examen; }
    public void setExamen(Double examen) { this.examen = examen; }
}

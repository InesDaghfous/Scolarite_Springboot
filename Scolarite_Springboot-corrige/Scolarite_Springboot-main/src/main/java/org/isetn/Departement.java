package org.isetn;

import com.fasterxml.jackson.annotation.JsonIgnore;
import javax.persistence.*;
import java.util.List;

@Entity
public class Departement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String codDept;
    private String nomDept;

    @JsonIgnore
    @OneToMany(mappedBy = "departement")
    private List<Classe> classes;

    public Departement() {}

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getCodDept() { return codDept; }
    public void setCodDept(String codDept) { this.codDept = codDept; }

    public String getNomDept() { return nomDept; }
    public void setNomDept(String nomDept) { this.nomDept = nomDept; }

    public List<Classe> getClasses() { return classes; }
    public void setClasses(List<Classe> classes) { this.classes = classes; }
}

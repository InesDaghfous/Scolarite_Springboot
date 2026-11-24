package org.isetn;

import com.fasterxml.jackson.annotation.JsonProperty;
import javax.persistence.*;

@Entity
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(unique = true, length = 100)
    private String email;

    @JsonProperty(access = JsonProperty.Access.WRITE_ONLY)
    private String password;

    @Column(length = 20)
    private String role = "ETUDIANT";

    public User() {}

    public User(Integer id, String email, String password, String role) {
        this.id = id;
        this.email = email;
        this.password = password;
        this.role = role != null ? role : "ETUDIANT";
    }

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
}

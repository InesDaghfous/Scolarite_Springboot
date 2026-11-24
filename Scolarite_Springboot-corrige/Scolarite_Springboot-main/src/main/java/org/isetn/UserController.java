package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
@CrossOrigin("*")
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody User user) {
        if (isBlank(user.getEmail()) || isBlank(user.getPassword())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Email et mot de passe obligatoires");
        }
        if (userRepository.existsByEmail(user.getEmail())) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body("Cet email est deja utilise");
        }
        user.setId(null);
        if (user.getRole() == null || user.getRole().isEmpty()) {
            user.setRole("ETUDIANT");
        }
        return ResponseEntity.ok(userRepository.save(user));
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {
        if (user.getEmail() == null || user.getPassword() == null) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST)
                    .body("Email et mot de passe obligatoires");
        }

        String email = user.getEmail().trim();
        String password = user.getPassword().trim();

        // 1. Chercher dans la base de données
        User found = userRepository.findByEmailAndPassword(email, password);

        // 2. Recherche tolérante (insensible à la casse de l'email)
        if (found == null) {
            for (User u : userRepository.findAll()) {
                if (u.getEmail() != null && u.getEmail().trim().equalsIgnoreCase(email)
                        && u.getPassword() != null && u.getPassword().equals(password)) {
                    found = u;
                    break;
                }
            }
        }

        // 3. Auto-création / fallback si la base a été vidée ou si les comptes par défaut n'existent pas encore
        if (found == null) {
            if ("admin@gmail.com".equalsIgnoreCase(email) && "admin".equals(password)) {
                User admin = new User();
                admin.setEmail("admin@gmail.com");
                admin.setPassword("admin");
                admin.setRole("ADMIN");
                found = userRepository.save(admin);
                System.out.println("✅ Compte admin@gmail.com initialisé automatiquement !");
            } else if ("etudiant@gmail.com".equalsIgnoreCase(email) && "1234".equals(password)) {
                User etu = new User();
                etu.setEmail("etudiant@gmail.com");
                etu.setPassword("1234");
                etu.setRole("ETUDIANT");
                found = userRepository.save(etu);
                System.out.println("✅ Compte etudiant@gmail.com initialisé automatiquement !");
            }
        }

        if (found == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body("Email ou mot de passe incorrect");
        }
        return ResponseEntity.ok(found);
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }
}

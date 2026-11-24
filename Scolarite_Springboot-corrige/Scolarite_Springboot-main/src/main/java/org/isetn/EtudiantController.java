package org.isetn;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/etudiants")
public class EtudiantController {

    @Autowired
    private EtudiantRepository etudiantRepository;

    @Autowired
    private ClasseRepository classeRepository;

    // GET /etudiants  → tous les étudiants
    @GetMapping
    public List<Etudiant> getAll() {
        return etudiantRepository.findAll();
    }

    // GET /etudiants/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Etudiant> getById(@PathVariable String id) {
        var byNce = etudiantRepository.findByNce(id);
        if (byNce.isPresent()) return ResponseEntity.ok(byNce.get());
        try {
            return etudiantRepository.findById(Long.parseLong(id))
                    .map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (NumberFormatException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // GET /etudiants/classe/{codClass}  → étudiants d'une classe par codClass ou id
    @GetMapping("/classe/{codClass}")
    public List<Etudiant> getByClasse(@PathVariable String codClass) {
        List<Etudiant> list = etudiantRepository.findByClasseCodClass(codClass);
        if (!list.isEmpty()) return list;
        try {
            Long classeId = Long.parseLong(codClass);
            return etudiantRepository.findByClasse_Id(classeId);
        } catch (NumberFormatException e) {
            return list;
        }
    }

    // POST /etudiants
    @PostMapping
    public ResponseEntity<Etudiant> create(@RequestBody Etudiant etudiant) {
        if (etudiant.getNce() == null || etudiant.getNce().isEmpty()) {
            String prefix = etudiant.getClasse() != null
                    && etudiant.getClasse().getCodClass() != null
                    ? etudiant.getClasse().getCodClass()
                    : "ETU";
            etudiant.setNce(prefix + (System.currentTimeMillis() % 100000));
        }
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(etudiantRepository.save(etudiant));
    }

    // PUT /etudiants/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Etudiant> update(@PathVariable String id,
                                            @RequestBody Etudiant etudiant) {
        // Chercher par nce ou id
        var existing = etudiantRepository.findByNce(id);
        Long numId = null;
        if (existing.isPresent()) {
            numId = existing.get().getId();
        } else {
            try {
                numId = Long.parseLong(id);
            } catch (NumberFormatException ignored) {}
        }

        if (numId == null || !etudiantRepository.existsById(numId)) {
            return ResponseEntity.notFound().build();
        }
        etudiant.setId(numId);
        return ResponseEntity.ok(etudiantRepository.save(etudiant));
    }

    // DELETE /etudiants/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        var existing = etudiantRepository.findByNce(id);
        Long numId = null;
        if (existing.isPresent()) {
            numId = existing.get().getId();
        } else {
            try {
                numId = Long.parseLong(id);
            } catch (NumberFormatException ignored) {}
        }

        if (numId == null || !etudiantRepository.existsById(numId)) {
            return ResponseEntity.notFound().build();
        }
        etudiantRepository.deleteById(numId);
        return ResponseEntity.noContent().build();
    }
}

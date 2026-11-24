package org.isetn;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/departements")
public class DepartementController {

    @Autowired
    private DepartementRepository departementRepository;

    @Autowired
    private ClasseRepository classeRepository;

    // GET /departements  → liste tous les départements
    @GetMapping
    public List<Departement> getAll() {
        return departementRepository.findAll();
    }

    // GET /departements/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Departement> getById(@PathVariable Long id) {
        return departementRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // GET /departements/{codDept}/classes  → classes du département
    @GetMapping("/{codDept}/classes")
    public List<Classe> getClassesByDept(@PathVariable String codDept) {
        return classeRepository.findByDepartementCodDept(codDept);
    }

    // POST /departements
    @PostMapping
    public Departement create(@RequestBody Departement dept) {
        return departementRepository.save(dept);
    }

    // PUT /departements/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Departement> update(@PathVariable Long id,
                                               @RequestBody Departement dept) {
        if (!departementRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        dept.setId(id);
        return ResponseEntity.ok(departementRepository.save(dept));
    }

    // DELETE /departements/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!departementRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        departementRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}


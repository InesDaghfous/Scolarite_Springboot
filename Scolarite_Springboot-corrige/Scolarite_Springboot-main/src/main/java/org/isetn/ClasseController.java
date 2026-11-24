package org.isetn;

import java.util.*;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/classes")
public class ClasseController {

    @Autowired
    private ClasseRepository classeRepository;

    @Autowired
    private EtudiantRepository etudiantRepository;

    // GET /classes  → toutes les classes
    @GetMapping
    public List<Classe> getAll() {
        return classeRepository.findAll();
    }

    // GET /classes/max-etudiants
    // Note : Ne pas utiliser la colonne NbrEtud de la table Classe,
    // mais compter le nombre effectif de lignes dans la table Etudiant.
    @GetMapping("/max-etudiants")
    public ResponseEntity<Map<String, Object>> getMaxEtudiants() {
        List<Classe> classes = classeRepository.findAll();
        List<Etudiant> etudiants = etudiantRepository.findAll();

        if (classes.isEmpty()) {
            return ResponseEntity.noContent().build();
        }

        // Compter les lignes dans la table Etudiant par classe
        Map<String, Long> countByCodClass = new HashMap<>();
        Map<String, List<Etudiant>> etudiantsByCodClass = new HashMap<>();

        for (Classe c : classes) {
            countByCodClass.put(c.getCodClass(), 0L);
            etudiantsByCodClass.put(c.getCodClass(), new ArrayList<>());
        }

        for (Etudiant e : etudiants) {
            if (e.getClasse() != null && e.getClasse().getCodClass() != null) {
                String code = e.getClasse().getCodClass();
                countByCodClass.put(code, countByCodClass.getOrDefault(code, 0L) + 1);
                etudiantsByCodClass.computeIfAbsent(code, k -> new ArrayList<>()).add(e);
            }
        }

        // Trouver la classe ayant le plus grand nombre d'étudiants dans la table Etudiant
        Classe maxClasse = null;
        long maxCount = -1;

        for (Classe c : classes) {
            long count = countByCodClass.getOrDefault(c.getCodClass(), 0L);
            if (count > maxCount) {
                maxCount = count;
                maxClasse = c;
            }
        }

        if (maxClasse == null) {
            return ResponseEntity.noContent().build();
        }

        Map<String, Object> res = new HashMap<>();
        res.put("classe", maxClasse);
        res.put("nombreEtudiantsReel", maxCount);
        res.put("nbreEtudActuel", maxClasse.getNbreEtud());
        res.put("etudiants", etudiantsByCodClass.getOrDefault(maxClasse.getCodClass(), Collections.emptyList()));
        res.put("statistiquesParClasse", countByCodClass);

        return ResponseEntity.ok(res);
    }

    // GET /classes/{id}
    @GetMapping("/{id}")
    public ResponseEntity<Classe> getById(@PathVariable String id) {
        var byCode = classeRepository.findByCodClass(id);
        if (byCode.isPresent()) return ResponseEntity.ok(byCode.get());
        try {
            return classeRepository.findById(Long.parseLong(id))
                    .map(ResponseEntity::ok)
                    .orElse(ResponseEntity.notFound().build());
        } catch (NumberFormatException e) {
            return ResponseEntity.notFound().build();
        }
    }

    // GET /classes/departement/{codDept}  → classes par département (codDept String ou id)
    @GetMapping("/departement/{codDept}")
    public List<Classe> getByDepartement(@PathVariable String codDept) {
        List<Classe> list = classeRepository.findByDepartementCodDept(codDept);
        if (!list.isEmpty()) return list;
        try {
            Long deptId = Long.parseLong(codDept);
            return classeRepository.findByDepartement_Id(deptId);
        } catch (NumberFormatException e) {
            return list;
        }
    }

    // POST /classes
    @PostMapping
    public Classe create(@RequestBody Classe classe) {
        return classeRepository.save(classe);
    }

    // PUT /classes/{idOrCode}/sync-effectif
    // Met à jour la colonne nbreEtud de cette classe spécifique avec le compte réel de la table Etudiant
    @PutMapping("/{idOrCode}/sync-effectif")
    public ResponseEntity<Classe> syncEffectif(@PathVariable String idOrCode) {
        Classe classe = classeRepository.findByCodClass(idOrCode)
                .orElseGet(() -> {
                    try {
                        return classeRepository.findById(Long.parseLong(idOrCode)).orElse(null);
                    } catch (NumberFormatException e) {
                        return null;
                    }
                });

        if (classe == null) {
            return ResponseEntity.notFound().build();
        }

        // Compter le nombre de lignes dans la table Etudiant pour cette classe
        long count = etudiantRepository.findAll().stream()
                .filter(e -> e.getClasse() != null && (
                        (classe.getId() != null && classe.getId().equals(e.getClasse().getId())) ||
                        (classe.getCodClass() != null && classe.getCodClass().equals(e.getClasse().getCodClass()))
                ))
                .count();

        classe.setNbreEtud((int) count);
        Classe saved = classeRepository.save(classe);
        return ResponseEntity.ok(saved);
    }

    // PUT /classes/{id}
    @PutMapping("/{id}")
    public ResponseEntity<Classe> update(@PathVariable String id,
                                          @RequestBody Classe classe) {
        Classe existing = classeRepository.findByCodClass(id)
                .orElseGet(() -> {
                    try {
                        return classeRepository.findById(Long.parseLong(id)).orElse(null);
                    } catch (NumberFormatException e) {
                        return null;
                    }
                });

        if (existing == null) {
            return ResponseEntity.notFound().build();
        }

        classe.setId(existing.getId());
        if (classe.getCodClass() == null || classe.getCodClass().isEmpty()) {
            classe.setCodClass(existing.getCodClass());
        }
        if (classe.getNomClass() == null || classe.getNomClass().isEmpty()) {
            classe.setNomClass(existing.getNomClass());
        }
        if (classe.getDepartement() == null) {
            classe.setDepartement(existing.getDepartement());
        }
        return ResponseEntity.ok(classeRepository.save(classe));
    }

    // DELETE /classes/{id}
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!classeRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        classeRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

package org.isetn;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/absences")
public class AbsenceController {

    @Autowired
    private AbsenceRepository absenceRepository;

    @Autowired
    private EtudiantRepository etudiantRepository;

    // ── GET /absences ─────────────────────────────────────────────────────────
    @GetMapping
    public List<Absence> getAllAbsences() {
        return absenceRepository.findAll();
    }

    // ── GET /absences/{id} ────────────────────────────────────────────────────
    @GetMapping("/{id}")
    public ResponseEntity<Absence> getAbsenceById(@PathVariable Long id) {
        return absenceRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── GET /absences/etudiant/{nce} ──────────────────────────────────────────
    // Flutter appelle cet endpoint avec le NCE de l'étudiant
    @GetMapping("/etudiant/{nce}")
    public List<Absence> getAbsencesByEtudiant(@PathVariable String nce) {
        // 1. Chercher par nce lié à l'étudiant (relation @ManyToOne)
        List<Absence> absences = absenceRepository.findByEtudiantNce(nce);
        if (!absences.isEmpty()) return absences;

        // 2. Chercher par le champ nce String direct sur Absence
        absences = absenceRepository.findByNce(nce);
        if (!absences.isEmpty()) return absences;

        // 3. Fallback : chercher par l'id de l'étudiant (si nce est un nombre)
        try {
            Long etudiantId = Long.parseLong(nce);
            return absenceRepository.findByEtudiant_Id(etudiantId);
        } catch (NumberFormatException e) {
            return absences;
        }
    }

    // ── GET /absences/search/findByEtudiantNce?nce={nce} ──────────────────────
    // Endpoint compatible Spring Data REST (appelé par Flutter en fallback)
    @GetMapping("/search/findByEtudiantNce")
    public List<Absence> findByEtudiantNce(@RequestParam String nce) {
        List<Absence> absences = absenceRepository.findByEtudiantNce(nce);
        if (!absences.isEmpty()) return absences;
        absences = absenceRepository.findByNce(nce);
        if (!absences.isEmpty()) return absences;
        try {
            Long etudiantId = Long.parseLong(nce);
            return absenceRepository.findByEtudiant_Id(etudiantId);
        } catch (NumberFormatException e) {
            return absences;
        }
    }

    // ── POST /absences ────────────────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<Absence> createAbsence(@RequestBody Absence absence) {
        // Si un nce est fourni, tenter de lier l'entité Etudiant
        if (absence.getNce() != null && !absence.getNce().isEmpty()) {
            // Chercher l'étudiant par nce
            etudiantRepository.findByNce(absence.getNce())
                    .ifPresent(absence::setEtudiant);
            // Si non trouvé par nce, essayer par id
            if (absence.getEtudiant() == null) {
                try {
                    Long etudiantId = Long.parseLong(absence.getNce());
                    etudiantRepository.findById(etudiantId)
                            .ifPresent(absence::setEtudiant);
                } catch (NumberFormatException e) {
                    // nce non numérique, on garde juste le champ String
                }
            }
        }
        Absence saved = absenceRepository.save(absence);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // ── PUT /absences/{id} ────────────────────────────────────────────────────
    @PutMapping("/{id}")
    public ResponseEntity<Absence> updateAbsence(@PathVariable Long id,
                                                  @RequestBody Absence absence) {
        if (!absenceRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        absence.setId(id);
        // Réappliquer le lien étudiant si nce fourni
        if (absence.getNce() != null && !absence.getNce().isEmpty()) {
            etudiantRepository.findByNce(absence.getNce())
                    .ifPresent(absence::setEtudiant);
            if (absence.getEtudiant() == null) {
                try {
                    Long etudiantId = Long.parseLong(absence.getNce());
                    etudiantRepository.findById(etudiantId)
                            .ifPresent(absence::setEtudiant);
                } catch (NumberFormatException e) {
                    // nce non numérique
                }
            }
        }
        return ResponseEntity.ok(absenceRepository.save(absence));
    }

    // ── DELETE /absences/{id} ─────────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteAbsence(@PathVariable Long id) {
        if (!absenceRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        absenceRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // ── GET /absences/classe/{codClass}/matiere/{codMat}/date/{dateA} ─────────
    // Retourne les absences déjà saisies pour une classe, une matière et une date
    @GetMapping("/classe/{codClass}/matiere/{codMat}/date/{dateA}")
    public List<Absence> getAbsencesByClasseMatDate(
            @PathVariable String codClass,
            @PathVariable String codMat,
            @PathVariable String dateA) {
        // On filtre par codMat + dateA, puis on garde ceux dont l'étudiant est dans la classe
        List<Absence> all = absenceRepository.findByCodMatAndDateA(codMat, dateA);
        List<Absence> result = new java.util.ArrayList<>();
        for (Absence a : all) {
            Etudiant et = a.getEtudiant();
            if (et != null && et.getClasse() != null
                    && codClass.equals(et.getClasse().getCodClass())) {
                result.add(a);
            } else if (et == null && a.getNce() != null) {
                // fallback : chercher l'étudiant par nce
                etudiantRepository.findByNce(a.getNce()).ifPresent(e -> {
                    if (e.getClasse() != null && codClass.equals(e.getClasse().getCodClass())) {
                        result.add(a);
                    }
                });
            }
        }
        return result;
    }

    // ── POST /absences/batch ──────────────────────────────────────────────────
    // Reçoit une liste d'absences à créer ou mettre à jour en une seule requête
    @PostMapping("/batch")
    public ResponseEntity<List<Absence>> batchSave(@RequestBody List<Absence> absences) {
        List<Absence> saved = new java.util.ArrayList<>();
        for (Absence absence : absences) {
            if (absence.getNce() != null && !absence.getNce().isEmpty()) {
                etudiantRepository.findByNce(absence.getNce())
                        .ifPresent(absence::setEtudiant);
            }
            saved.add(absenceRepository.save(absence));
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }
}

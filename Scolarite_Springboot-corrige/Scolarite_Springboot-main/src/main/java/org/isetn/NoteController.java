package org.isetn;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@CrossOrigin("*")
@RequestMapping("/notes")
public class NoteController {

    @Autowired
    private NoteRepository noteRepository;

    // ── GET /notes ───────────────────────────────────────────────────────────
    @GetMapping
    public List<Note> getAll() {
        return noteRepository.findAll();
    }

    // ── GET /notes/{id} ──────────────────────────────────────────────────────
    @GetMapping("/{id}")
    public ResponseEntity<Note> getById(@PathVariable Long id) {
        return noteRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // ── GET /notes/etudiant/{nce} ────────────────────────────────────────────
    @GetMapping("/etudiant/{nce}")
    public List<Note> getByEtudiant(@PathVariable String nce) {
        return noteRepository.findByNce(nce);
    }

    // ── POST /notes ──────────────────────────────────────────────────────────
    @PostMapping
    public ResponseEntity<Note> create(@RequestBody Note note) {
        if (note.getCoef() <= 0) {
            note.setCoef(1.0);
        }
        Note saved = noteRepository.save(note);
        return ResponseEntity.status(HttpStatus.CREATED).body(saved);
    }

    // ── PUT /notes/{id} ──────────────────────────────────────────────────────
    @PutMapping("/{id}")
    public ResponseEntity<Note> update(@PathVariable Long id, @RequestBody Note note) {
        if (!noteRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        note.setId(id);
        if (note.getCoef() <= 0) {
            note.setCoef(1.0);
        }
        return ResponseEntity.ok(noteRepository.save(note));
    }

    // ── DELETE /notes/{id} ───────────────────────────────────────────────────
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        if (!noteRepository.existsById(id)) {
            return ResponseEntity.notFound().build();
        }
        noteRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}

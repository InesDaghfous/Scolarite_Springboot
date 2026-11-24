package org.isetn;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.text.SimpleDateFormat;
import java.util.List;

@Component
public class DataInitializer implements CommandLineRunner {

    @Autowired
    private DepartementRepository departementRepo;

    @Autowired
    private ClasseRepository classeRepo;

    @Autowired
    private EtudiantRepository etudiantRepo;

    @Autowired
    private AbsenceRepository absenceRepo;

    @Autowired
    private FormationRepository formationRepo;

    @Autowired
    private NoteRepository noteRepo;

    @Override
    public void run(String... args) throws Exception {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

        // ── Initialisation des Départements, Classes, Étudiants si absents ────
        if (departementRepo.count() == 0) {
            // ── 1. Départements ──────────────────────────────────────────────
            Departement ti = new Departement();
            ti.setCodDept("TI");
            ti.setNomDept("Technologies de l'Information");
            ti = departementRepo.save(ti);

            Departement ge = new Departement();
            ge.setCodDept("GE");
            ge.setNomDept("Génie Électrique");
            ge = departementRepo.save(ge);

            // ── 2. Formations ────────────────────────────────────────────────
            Formation dsi = new Formation();
            dsi.setNom("Développement des Systèmes d'Information");
            dsi.setDuree(3);
            dsi = formationRepo.save(dsi);

            Formation rt = new Formation();
            rt.setNom("Réseaux et Télécommunications");
            rt.setDuree(3);
            rt = formationRepo.save(rt);

            // ── 3. Classes ───────────────────────────────────────────────────
            Classe dsi33 = new Classe();
            dsi33.setCodClass("DSI33");
            dsi33.setNomClass("DSI – 3ème Année A");
            dsi33.setNbreEtud(25);
            dsi33.setDepartement(ti);
            dsi33 = classeRepo.save(dsi33);

            Classe dsi31 = new Classe();
            dsi31.setCodClass("DSI31");
            dsi31.setNomClass("DSI – 3ème Année B");
            dsi31.setNbreEtud(22);
            dsi31.setDepartement(ti);
            dsi31 = classeRepo.save(dsi31);

            Classe rt31 = new Classe();
            rt31.setCodClass("RT31");
            rt31.setNomClass("RT – 3ème Année");
            rt31.setNbreEtud(20);
            rt31.setDepartement(ge);
            rt31 = classeRepo.save(rt31);

            // ── 4. Étudiants ─────────────────────────────────────────────────
            Etudiant e1 = new Etudiant();
            e1.setNce("DSI33001");
            e1.setNom("Ben Ali");
            e1.setPrenom("Mohamed");
            e1.setDateNais(sdf.parse("2001-05-10"));
            e1.setLieuNais("Tunis");
            e1.setFormation(dsi);
            e1.setClasse(dsi33);
            e1 = etudiantRepo.save(e1);

            Etudiant e2 = new Etudiant();
            e2.setNce("DSI33002");
            e2.setNom("Trabelsi");
            e2.setPrenom("Fatma");
            e2.setDateNais(sdf.parse("2002-03-20"));
            e2.setLieuNais("Nabeul");
            e2.setFormation(dsi);
            e2.setClasse(dsi33);
            e2 = etudiantRepo.save(e2);

            Etudiant e3 = new Etudiant();
            e3.setNce("DSI33003");
            e3.setNom("Chaabane");
            e3.setPrenom("Ahmed");
            e3.setDateNais(sdf.parse("2001-11-15"));
            e3.setLieuNais("Sousse");
            e3.setFormation(dsi);
            e3.setClasse(dsi33);
            e3 = etudiantRepo.save(e3);

            Etudiant e4 = new Etudiant();
            e4.setNce("DSI31001");
            e4.setNom("Hamdi");
            e4.setPrenom("Sana");
            e4.setDateNais(sdf.parse("2002-07-08"));
            e4.setLieuNais("Bizerte");
            e4.setFormation(dsi);
            e4.setClasse(dsi31);
            etudiantRepo.save(e4);

            Etudiant e5 = new Etudiant();
            e5.setNce("RT31001");
            e5.setNom("Mbarki");
            e5.setPrenom("Nour");
            e5.setDateNais(sdf.parse("2002-01-30"));
            e5.setLieuNais("Monastir");
            e5.setFormation(rt);
            e5.setClasse(rt31);
            etudiantRepo.save(e5);

            // ── 5. Absences de test ──────────────────────────────────────────
            Absence a1 = new Absence();
            a1.setCodMat("AFCP");
            a1.setNce(e1.getNce());
            a1.setDateA("10-11-2025");
            a1.setNha(1.5);
            a1.setEtudiant(e1);
            absenceRepo.save(a1);

            Absence a2 = new Absence();
            a2.setCodMat("SOA");
            a2.setNce(e1.getNce());
            a2.setDateA("12-11-2025");
            a2.setNha(3.0);
            a2.setEtudiant(e1);
            absenceRepo.save(a2);

            Absence a3 = new Absence();
            a3.setCodMat("AFCP");
            a3.setNce(e1.getNce());
            a3.setDateA("17-11-2025");
            a3.setNha(1.5);
            a3.setEtudiant(e1);
            absenceRepo.save(a3);

            System.out.println("✅ Départements, Classes et Étudiants initialisés avec succès !");
        }

        // ── 6. Initialisation des Notes si absentes ───────────────────────────
        if (noteRepo.count() == 0) {
            // Étudiant DSI33001 (Ben Ali Mohamed)
            // 1. Matière complète (TPs 50/50 + DS/Exam 40/60)
            Note n1 = new Note();
            n1.setNce("DSI33001");
            n1.setCodMat("AFCP");
            n1.setNomMat("Architecture & Frameworks");
            n1.setCoef(2.0);
            n1.setTp1(15.0);
            n1.setTp2(17.0);
            n1.setDs(14.0);
            n1.setExamen(16.0);
            noteRepo.save(n1);

            // 2. Matière avec seulement TPs (50/50)
            Note n2 = new Note();
            n2.setNce("DSI33001");
            n2.setCodMat("M012");
            n2.setNomMat("Atelier Développement Web");
            n2.setCoef(1.5);
            n2.setTp1(18.0);
            n2.setTp2(17.0);
            n2.setDs(null);
            n2.setExamen(null);
            noteRepo.save(n2);

            // 3. Matière avec seulement DS et Examen (40/60)
            Note n3 = new Note();
            n3.setNce("DSI33001");
            n3.setCodMat("SOA");
            n3.setNomMat("Services Web & Microservices");
            n3.setCoef(1.5);
            n3.setTp1(null);
            n3.setTp2(null);
            n3.setDs(13.0);
            n3.setExamen(15.5);
            noteRepo.save(n3);

            // 4. Matière Bases de données
            Note n4 = new Note();
            n4.setNce("DSI33001");
            n4.setCodMat("BD");
            n4.setNomMat("Bases de Données Avancées");
            n4.setCoef(2.0);
            n4.setTp1(14.0);
            n4.setTp2(16.0);
            n4.setDs(12.0);
            n4.setExamen(13.5);
            noteRepo.save(n4);

            // Étudiant DSI33002 (Trabelsi Fatma)
            Note n5 = new Note();
            n5.setNce("DSI33002");
            n5.setCodMat("AFCP");
            n5.setNomMat("Architecture & Frameworks");
            n5.setCoef(2.0);
            n5.setTp1(14.0);
            n5.setTp2(15.0);
            n5.setDs(11.0);
            n5.setExamen(12.0);
            noteRepo.save(n5);

            Note n6 = new Note();
            n6.setNce("DSI33002");
            n6.setCodMat("ALGO");
            n6.setNomMat("Algorithmique Avancée");
            n6.setCoef(2.0);
            n6.setTp1(null);
            n6.setTp2(null);
            n6.setDs(16.0);
            n6.setExamen(17.5);
            noteRepo.save(n6);

            Note n7 = new Note();
            n7.setNce("DSI33002");
            n7.setCodMat("M012");
            n7.setNomMat("Atelier Développement Web");
            n7.setCoef(1.5);
            n7.setTp1(16.0);
            n7.setTp2(15.5);
            n7.setDs(null);
            n7.setExamen(null);
            noteRepo.save(n7);

            System.out.println("✅ Relevés de notes de test initialisés avec succès !");
        }
    }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helper.dart';
import 'absence.dart';
import 'absence_total_screen.dart';
import 'classe.dart';
import 'departement.dart';
import 'etudiant.dart';
import 'user.dart';

/// Écran réservé à l'Étudiant (Lecture seule)
/// L'étudiant ne peut ni ajouter, ni modifier, ni supprimer.
/// Il peut uniquement consulter ses absences, voir le total par matière et le graphique.
class MesAbsencesScreen extends StatefulWidget {
  final User user;

  const MesAbsencesScreen({super.key, required this.user});

  @override
  State<MesAbsencesScreen> createState() => _MesAbsencesScreenState();
}

class _MesAbsencesScreenState extends State<MesAbsencesScreen> {
  Etudiant? _etudiant;
  List<Etudiant> _allEtudiants = [];
  List<Absence> _absences = [];
  Classe? _classe;
  Departement? _departement;

  bool _loading = true;
  bool _loadingAbsences = false;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/etudiants'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        final etudiants = list
            .map((e) => Etudiant.fromMap(e as Map<String, dynamic>))
            .toList();

        _allEtudiants = etudiants;

        // Tenter de retrouver l'étudiant lié à cet utilisateur :
        // 1. Par ID
        // 2. Par correspondance d'email (ex: benflen / foulen)
        Etudiant? match;
        if (etudiants.isNotEmpty) {
          final emailPrefix = widget.user.email
              .split('@')[0]
              .toLowerCase()
              .replaceAll(RegExp(r'[^a-z0-9]'), '');

          match = etudiants.firstWhere(
            (e) =>
                e.nce == widget.user.id.toString() ||
                e.nom.toLowerCase().contains(emailPrefix) ||
                e.prenom.toLowerCase().contains(emailPrefix) ||
                emailPrefix.contains(e.nom.toLowerCase()) ||
                emailPrefix.contains(e.prenom.toLowerCase()),
            orElse: () => etudiants.first,
          );
        }

        setState(() {
          _etudiant = match;
        });

        if (match != null) {
          await _loadAbsencesForStudent(match);
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement profil étudiant: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadAbsencesForStudent(Etudiant etudiant) async {
    setState(() => _loadingAbsences = true);
    try {
      // 1. Absences
      var res = await http.get(Uri.parse('$baseUrl/absences/etudiant/${etudiant.nce}'));
      if (res.statusCode != 200) {
        res = await http.get(
            Uri.parse('$baseUrl/absences/search/findByEtudiantNce?nce=${etudiant.nce}'));
      }

      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'absences');
        _absences = list
            .map((e) => Absence.fromMap(e as Map<String, dynamic>))
            .toList();
      }

      // 2. Classe
      if (etudiant.codClass.isNotEmpty) {
        final cRes = await http.get(Uri.parse('$baseUrl/classes/${etudiant.codClass}'));
        if (cRes.statusCode == 200) {
          _classe = Classe.fromMap(jsonDecode(cRes.body));
        }
      }
      _classe ??= Classe(
        codClass: etudiant.codClass.isNotEmpty ? etudiant.codClass : 'DSI33',
        nomClass: 'Classe ${etudiant.codClass}',
        nbrEtud: 25,
        codDept: 'TI',
      );

      // 3. Département
      _departement = Departement(
        codDept: _classe?.codDept.isNotEmpty == true ? _classe!.codDept : 'TI',
        nomDept: 'Technologies de l\'Information',
      );
    } catch (e) {
      debugPrint('Erreur chargement absences étudiant: $e');
    } finally {
      if (mounted) setState(() => _loadingAbsences = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Absences', style: GoogleFonts.oswald()),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser mes absences',
            onPressed: _etudiant == null
                ? null
                : () => _loadAbsencesForStudent(_etudiant!),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Carte Profil de l'étudiant (Lecture seule) ─────────────
                  _buildStudentInfoCard(),
                  const SizedBox(height: 16),

                  // ── Tableau des absences (Lecture seule) ───────────────────
                  _buildAbsencesCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      // AUCUN FloatingActionButton : l'étudiant ne peut pas ajouter d'absence !
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.teal.shade100,
                  child: Icon(Icons.person, color: Colors.teal.shade800, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _etudiant != null
                            ? '${_etudiant!.nom} ${_etudiant!.prenom}'
                            : widget.user.email,
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      Text(
                        'Compte Étudiant (${widget.user.email})',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.teal.shade300),
                  ),
                  child: const Text(
                    'Lecture seule',
                    style: TextStyle(
                      color: Colors.teal,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _infoRow('NCE / ID', _etudiant?.nce ?? '${widget.user.id}'),
            _infoRow('Classe', _classe?.nomClass ?? 'DSI33'),
            _infoRow('Département', _departement?.nomDept ?? 'TI'),

            // Sélecteur si plusieurs profils disponibles
            if (_allEtudiants.length > 1) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<Etudiant>(
                value: _etudiant,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Changer d\'étudiant (profil)',
                  prefixIcon: const Icon(Icons.swap_horiz, color: Colors.teal),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  isDense: true,
                ),
                items: _allEtudiants
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('${e.nce} – ${e.nom} ${e.prenom}'),
                        ))
                    .toList(),
                onChanged: (e) {
                  if (e != null) {
                    setState(() => _etudiant = e);
                    _loadAbsencesForStudent(e);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbsencesCard() {
    if (_loadingAbsences) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec bouton Totaux & Graphique
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Mes Absences (${_absences.length})',
                    style: GoogleFonts.oswald(
                      fontSize: 20,
                      color: Colors.teal.shade800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _absences.isEmpty || _etudiant == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AbsenceTotalScreen(
                                etudiant: _etudiant!,
                                absences: _absences,
                                classe: _classe ??
                                    Classe(
                                      codClass: 'DSI33',
                                      nomClass: 'DSI33',
                                      nbrEtud: 25,
                                      codDept: 'TI',
                                    ),
                                departement: _departement ??
                                    Departement(
                                      codDept: 'TI',
                                      nomDept: 'TI',
                                    ),
                              ),
                            ),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Totaux & Graphe'),
                ),
              ],
            ),
          ),

          // Message informatif pour l'étudiant
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode consultation : seul l\'administrateur peut modifier ou ajouter des absences.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Tableau des absences
          if (_absences.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Félicitations ! Aucune absence enregistrée.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.teal.shade50),
                columnSpacing: 28,
                columns: const [
                  DataColumn(
                    label: Text(
                      'DateA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'CodMat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'NHA (heures)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                // AUCUNE colonne d'action : l'étudiant ne peut pas modifier/supprimer
                rows: _absences
                    .map(
                      (a) => DataRow(cells: [
                        DataCell(Text(a.dateA)),
                        DataCell(
                          Chip(
                            label: Text(
                              a.codMat,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: Colors.teal,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        DataCell(
                          Text(
                            '${a.nha} h',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ]),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

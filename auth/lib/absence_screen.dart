import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helper.dart';
import 'absence.dart';
import 'classe.dart';
import 'departement.dart';
import 'etudiant.dart';
import 'absence_total_screen.dart';
import 'releve_notes_screen.dart';
import 'user.dart';

class AbsenceScreen extends StatefulWidget {
  final User? currentUser;
  const AbsenceScreen({super.key, this.currentUser});

  @override
  State<AbsenceScreen> createState() => _AbsenceScreenState();
}

class _AbsenceScreenState extends State<AbsenceScreen> {
  bool get _isAdmin => widget.currentUser?.isAdmin ?? true;

  // ── listes chargées depuis l'API ──────────────────────────────────────────
  List<Departement> _departements = [];
  List<Classe> _allClasses = [];
  List<Classe> _classes = [];
  List<Etudiant> _etudiants = [];
  List<Absence> _absences = [];

  // ── sélections courantes ──────────────────────────────────────────────────
  Departement? _selectedDept;
  Classe? _selectedClasse;
  Etudiant? _selectedEtudiant;

  // ── champs affichage étudiant ─────────────────────────────────────────────
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();

  // ── indicateurs de chargement ─────────────────────────────────────────────
  bool _loadingDepts = false;
  bool _loadingClasses = false;
  bool _loadingEtudiants = false;
  bool _loadingAbsences = false;

  @override
  void initState() {
    super.initState();
    _fetchDepartementsAndClasses();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  // Appels API
  // =========================================================================
  Future<void> _fetchDepartementsAndClasses() async {
    await Future.wait([
      _fetchDepartements(),
      _fetchAllClasses(),
    ]);
  }

  Future<void> _fetchDepartements() async {
    setState(() => _loadingDepts = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/departements'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'departements');
        setState(() {
          _departements = list.map((e) => Departement.fromMap(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {
      _showError('Serveur Spring Boot inaccessible ($baseUrl)');
    } finally {
      setState(() => _loadingDepts = false);
    }
  }

  Future<void> _fetchAllClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/classes'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'classes');
        final classes = list.map((e) => Classe.fromMap(e as Map<String, dynamic>)).toList();
        setState(() {
          _allClasses = classes;
          if (_selectedDept == null) {
            _classes = List.from(classes);
          } else {
            _classes = classes
                .where((c) => c.codDept.isEmpty || c.codDept == _selectedDept!.codDept)
                .toList();
          }
        });
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _fetchClasses(String codDept) async {
    setState(() {
      _loadingClasses = true;
      _selectedClasse = null;
      _etudiants = [];
      _selectedEtudiant = null;
      _absences = [];
      _nomCtrl.clear();
      _prenomCtrl.clear();
    });
    try {
      var res = await http.get(Uri.parse('$baseUrl/classes/departement/$codDept'));
      if (res.statusCode != 200) {
        res = await http.get(Uri.parse('$baseUrl/classes/search/findByDepartementCodDept?codDept=$codDept'));
      }
      if (res.statusCode != 200) {
        res = await http.get(Uri.parse('$baseUrl/classes'));
      }

      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'classes');
        final fetched = list.map((e) => Classe.fromMap(e as Map<String, dynamic>)).toList();
        setState(() {
          _classes = fetched
              .where((c) => c.codDept.isEmpty || c.codDept == codDept)
              .toList();
          if (_classes.isEmpty) _classes = fetched;
        });
      }
    } catch (_) {
      // Fallback sur _allClasses filtrées en local
      setState(() {
        _classes = _allClasses
            .where((c) => c.codDept.isEmpty || c.codDept == codDept)
            .toList();
        if (_classes.isEmpty) _classes = List.from(_allClasses);
      });
    } finally {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _fetchEtudiants(String codClass) async {
    setState(() {
      _loadingEtudiants = true;
      _etudiants = [];
      _selectedEtudiant = null;
      _absences = [];
      _nomCtrl.clear();
      _prenomCtrl.clear();
    });
    try {
      var res = await http.get(Uri.parse('$baseUrl/etudiants/classe/$codClass'));
      if (res.statusCode != 200) {
        res = await http.get(
          Uri.parse('$baseUrl/etudiants/search/findByClasseCodClass?codClass=$codClass&projection=p1'),
        );
      }

      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        setState(() {
          _etudiants = list.map((e) => Etudiant.fromMap(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {
      _showError('Erreur chargement étudiants');
    } finally {
      setState(() => _loadingEtudiants = false);
    }
  }

  Future<void> _fetchAbsences(String nce) async {
    setState(() {
      _loadingAbsences = true;
      _absences = [];
    });
    try {
      var res = await http.get(Uri.parse('$baseUrl/absences/etudiant/$nce'));
      if (res.statusCode != 200) {
        res = await http.get(Uri.parse('$baseUrl/absences/search/findByEtudiantNce?nce=$nce'));
      }

      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'absences');
        setState(() {
          _absences = list.map((e) => Absence.fromMap(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {
      _showError('Erreur chargement absences');
    } finally {
      setState(() => _loadingAbsences = false);
    }
  }

  Future<void> _addAbsence(Absence a) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/absences'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(a.toMap()),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (_selectedEtudiant != null) {
          await _fetchAbsences(_selectedEtudiant!.nce);
        }
        _showSuccess('Absence ajoutée ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _updateAbsence(Absence a) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/absences/${a.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(a.toMap()),
      );
      if (res.statusCode == 200) {
        if (_selectedEtudiant != null) {
          await _fetchAbsences(_selectedEtudiant!.nce);
        }
        _showSuccess('Absence mise à jour ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _deleteAbsence(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/absences/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        if (_selectedEtudiant != null) {
          await _fetchAbsences(_selectedEtudiant!.nce);
        }
        _showSuccess('Absence supprimée ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // =========================================================================
  // Messages utilisateur
  // =========================================================================
  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // =========================================================================
  // Dialogue Ajouter / Modifier une absence
  // =========================================================================
  void _showAbsenceDialog({Absence? existing}) {
    if (_selectedEtudiant == null && existing == null) {
      _showError('Veuillez d\'abord sélectionner un étudiant dans la liste.');
      return;
    }

    final codMatCtrl = TextEditingController(text: existing?.codMat ?? '');
    final dateCtrl = TextEditingController(
      text: existing?.dateA ??
          '${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().year}',
    );
    final nhaCtrl = TextEditingController(text: existing?.nha.toString() ?? '1.5');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null
              ? 'Ajouter absence pour ${_selectedEtudiant?.fullName ?? ""}'
              : 'Modifier l\'absence',
          style: GoogleFonts.oswald(color: Colors.purple, fontSize: 18),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codMatCtrl,
                decoration: const InputDecoration(
                  labelText: 'Code Matière (ex: AFCP, SOA, ALGO)',
                  prefixIcon: Icon(Icons.book_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date (JJ-MM-AAAA)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    dateCtrl.text =
                        '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
                  }
                },
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nhaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'NHA (Nombre d\'heures, ex: 1.5, 3)',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Champ requis';
                  if (double.tryParse(v.trim()) == null) {
                    return 'Nombre invalide';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final absence = Absence(
                id: existing?.id,
                codMat: codMatCtrl.text.trim().toUpperCase(),
                nce: existing?.nce ?? _selectedEtudiant!.nce,
                dateA: dateCtrl.text.trim(),
                nha: double.parse(nhaCtrl.text.trim()),
              );
              existing == null
                  ? _addAbsence(absence)
                  : _updateAbsence(absence);
            },
            child: Text(
              existing == null ? 'Ajouter' : 'Modifier',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Absence a) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Supprimer l\'absence du ${a.dateA} en ${a.codMat} (${a.nha} h) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              if (a.id != null) _deleteAbsence(a.id!);
            },
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  InputDecoration _dropDecor(String label, IconData icon) =>
      InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: Colors.purple),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );

  Widget _buildSelectionCard() {
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
                Expanded(
                  child: Text(
                    'Sélection en cascade',
                    style: GoogleFonts.oswald(fontSize: 20, color: Colors.purple),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.purple),
                  tooltip: 'Actualiser',
                  onPressed: _fetchDepartementsAndClasses,
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── 1. Première liste : Département ──────────────────────────
            if (_loadingDepts)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<Departement?>(
                value: _selectedDept,
                isExpanded: true,
                decoration: _dropDecor('1. Département (Optionnel)', Icons.business),
                hint: const Text('Tous les départements'),
                items: [
                  const DropdownMenuItem<Departement?>(
                    value: null,
                    child: Text('--- Tous les départements ---'),
                  ),
                  ..._departements.map((d) => DropdownMenuItem<Departement?>(
                        value: d,
                        child: Text('${d.codDept} - ${d.nomDept}'),
                      )),
                ],
                onChanged: (d) {
                  setState(() => _selectedDept = d);
                  if (d != null) {
                    _fetchClasses(d.codDept);
                  } else {
                    setState(() {
                      _classes = List.from(_allClasses);
                      _selectedClasse = null;
                      _etudiants = [];
                      _selectedEtudiant = null;
                      _absences = [];
                      _nomCtrl.clear();
                      _prenomCtrl.clear();
                    });
                  }
                },
              ),

            const SizedBox(height: 12),

            // ── 2. Deuxième liste : Classe ───────────────────────────────
            if (_loadingClasses)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<Classe?>(
                value: _selectedClasse,
                isExpanded: true,
                decoration: _dropDecor('2. Classe', Icons.class_),
                hint: Text(_classes.isEmpty
                    ? 'Aucune classe disponible'
                    : 'Sélectionner une classe (${_classes.length})'),
                items: [
                  ..._classes.map((c) => DropdownMenuItem<Classe?>(
                        value: c,
                        child: Text('${c.codClass} – ${c.nomClass}'),
                      )),
                ],
                onChanged: _classes.isEmpty
                    ? null
                    : (c) {
                        setState(() => _selectedClasse = c);
                        if (c != null) _fetchEtudiants(c.codClass);
                      },
              ),

            const SizedBox(height: 12),

            // ── 3. Troisième liste : Étudiant ────────────────────────────
            if (_loadingEtudiants)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<Etudiant?>(
                value: _selectedEtudiant,
                isExpanded: true,
                decoration: _dropDecor('3. Étudiant', Icons.person),
                hint: Text(_selectedClasse == null
                    ? 'Choisissez une classe d\'abord'
                    : (_etudiants.isEmpty
                        ? 'Aucun étudiant dans cette classe'
                        : 'Sélectionner un étudiant (${_etudiants.length})')),
                items: [
                  ..._etudiants.map((e) => DropdownMenuItem<Etudiant?>(
                        value: e,
                        child: Text('${e.nce} – ${e.nom} ${e.prenom}'),
                      )),
                ],
                onChanged: _etudiants.isEmpty
                    ? null
                    : (e) {
                        setState(() {
                          _selectedEtudiant = e;
                          if (e != null) {
                            _nomCtrl.text = e.nom;
                            _prenomCtrl.text = e.prenom;
                            _fetchAbsences(e.nce);
                          }
                        });
                      },
              ),

            const SizedBox(height: 14),

            // ── 4. Zones textes : Nom et Prénom après sélection ───────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nomCtrl,
                    readOnly: true,
                    decoration: _dropDecor('Nom', Icons.badge),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _prenomCtrl,
                    readOnly: true,
                    decoration: _dropDecor('Prénom', Icons.badge_outlined),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAbsencesCard() {
    if (_selectedEtudiant == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 40, color: Colors.purple.shade300),
                const SizedBox(height: 10),
                const Text(
                  'Sélectionnez une classe puis un étudiant\npour afficher et gérer ses absences',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadingAbsences) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Absences (${_absences.length})',
                  style: GoogleFonts.oswald(fontSize: 20, color: Colors.purple),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReleveNotesScreen(
                        etudiant: _selectedEtudiant!,
                        currentUser: widget.currentUser,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.school, size: 18, color: Colors.indigo),
                  label: const Text('Relevé de notes', style: TextStyle(color: Colors.indigo)),
                ),
                TextButton.icon(
                  onPressed: _absences.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AbsenceTotalScreen(
                                etudiant: _selectedEtudiant!,
                                absences: _absences,
                                classe: _selectedClasse ??
                                    Classe(
                                      codClass: _selectedEtudiant!.codClass,
                                      nomClass: _selectedEtudiant!.codClass,
                                      nbrEtud: 25,
                                      codDept: 'TI',
                                    ),
                                departement: _selectedDept ??
                                    Departement(
                                      codDept: 'TI',
                                      nomDept: 'TI',
                                    ),
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.bar_chart, size: 18),
                  label: const Text('Totaux & Graphe'),
                ),
              ],
            ),
          ),

          if (_absences.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Aucune absence enregistrée pour cet étudiant',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.purple.shade50),
                columnSpacing: 20,
                columns: [
                  const DataColumn(
                      label: Text('DateA',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text('CodMat',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  const DataColumn(
                      label: Text('NHA',
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  if (_isAdmin)
                    const DataColumn(
                        label: Text('Actions',
                            style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: _absences
                    .map(
                      (a) => DataRow(cells: [
                        DataCell(Text(a.dateA)),
                        DataCell(
                          Chip(
                            label: Text(a.codMat,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white)),
                            backgroundColor: Colors.purple,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        DataCell(Text(
                          '${a.nha} h',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                        if (_isAdmin)
                          DataCell(Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Modifier',
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue, size: 20),
                                onPressed: () =>
                                    _showAbsenceDialog(existing: a),
                              ),
                              IconButton(
                                tooltip: 'Supprimer',
                                icon: const Icon(Icons.delete,
                                    color: Colors.red, size: 20),
                                onPressed: () => _confirmDelete(a),
                              ),
                            ],
                          )),
                      ]),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Absences', style: GoogleFonts.oswald()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger',
            onPressed: _fetchDepartementsAndClasses,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _buildSelectionCard(),
            const SizedBox(height: 14),
            _buildAbsencesCard(),
            const SizedBox(height: 90),
          ],
        ),
      ),
      floatingActionButton: !_isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (_selectedEtudiant == null) {
                  _showError('Veuillez d\'abord choisir une classe et un étudiant.');
                } else {
                  _showAbsenceDialog();
                }
              },
              backgroundColor: Colors.purple,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter absence (+)',
                  style: TextStyle(color: Colors.white)),
            ),
    );
  }
}

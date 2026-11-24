import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helper.dart';
import 'etudiant.dart';
import 'note.dart';
import 'user.dart';

class ReleveNotesScreen extends StatefulWidget {
  final Etudiant? etudiant;
  final User? currentUser;

  const ReleveNotesScreen({
    super.key,
    this.etudiant,
    this.currentUser,
  });

  @override
  State<ReleveNotesScreen> createState() => _ReleveNotesScreenState();
}

class _ReleveNotesScreenState extends State<ReleveNotesScreen> {
  bool get _isAdmin => widget.currentUser?.isAdmin ?? true;

  Etudiant? _etudiant;
  List<Etudiant> _allEtudiants = [];
  List<Note> _notes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.etudiant != null) {
      _etudiant = widget.etudiant;
      _fetchNotes();
      _loadAllStudentsBackground();
    } else {
      _loadStudentsAndNotes();
    }
  }

  Future<void> _loadAllStudentsBackground() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/etudiants'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        final students = list.map((e) => Etudiant.fromMap(e as Map<String, dynamic>)).toList();
        if (mounted) {
          setState(() {
            _allEtudiants = students;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadStudentsAndNotes() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/etudiants'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        final students = list.map((e) => Etudiant.fromMap(e as Map<String, dynamic>)).toList();
        _allEtudiants = students;

        Etudiant? match;
        if (students.isNotEmpty) {
          if (widget.currentUser != null && widget.currentUser!.isStudent) {
            final emailPrefix = widget.currentUser!.email
                .split('@')[0]
                .toLowerCase()
                .replaceAll(RegExp(r'[^a-z0-9]'), '');

            match = students.firstWhere(
              (e) =>
                  e.nce == widget.currentUser!.id.toString() ||
                  e.nom.toLowerCase().contains(emailPrefix) ||
                  e.prenom.toLowerCase().contains(emailPrefix) ||
                  emailPrefix.contains(e.nom.toLowerCase()) ||
                  emailPrefix.contains(e.prenom.toLowerCase()),
              orElse: () => students.first,
            );
          } else {
            match = students.first;
          }
        }

        _etudiant = match;
        if (match != null) {
          await _fetchNotesForStudent(match.nce);
        }
      }
    } catch (e) {
      _showError('Serveur inaccessible ($baseUrl)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // =========================================================================
  // Appels API
  // =========================================================================
  Future<void> _fetchNotes() async {
    if (_etudiant == null) return;
    await _fetchNotesForStudent(_etudiant!.nce);
  }

  Future<void> _fetchNotesForStudent(String nce) async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/notes/etudiant/$nce'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'notes');
        setState(() {
          _notes = list.map((e) => Note.fromMap(e as Map<String, dynamic>)).toList();
        });
      } else {
        _showError('Erreur ${res.statusCode} lors du chargement des notes');
      }
    } catch (e) {
      _showError('Serveur inaccessible ($baseUrl)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addNote(Note note) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toMap()),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        await _fetchNotes();
        _showSuccess('Note enregistrée ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _updateNote(Note note) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/notes/${note.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(note.toMap()),
      );
      if (res.statusCode == 200) {
        await _fetchNotes();
        _showSuccess('Note mise à jour ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/notes/$id'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        await _fetchNotes();
        _showSuccess('Note supprimée ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  // =========================================================================
  // Calculs
  // =========================================================================
  double get _moyenneGenerale {
    if (_notes.isEmpty) return 0.0;
    double sumPoints = 0.0;
    double sumCoef = 0.0;
    for (final n in _notes) {
      sumPoints += n.moyenneMatiere * n.coef;
      sumCoef += n.coef;
    }
    if (sumCoef == 0) return 0.0;
    return sumPoints / sumCoef;
  }

  double get _totalCoef {
    return _notes.fold(0.0, (acc, n) => acc + n.coef);
  }

  String get _mention {
    final moy = _moyenneGenerale;
    if (_notes.isEmpty) return 'Aucune note';
    if (moy >= 16) return 'Très Bien';
    if (moy >= 14) return 'Bien';
    if (moy >= 12) return 'Assez Bien';
    if (moy >= 10) return 'Passable (Admis)';
    return 'Ajourné';
  }

  Color get _mentionColor {
    final moy = _moyenneGenerale;
    if (_notes.isEmpty) return Colors.grey;
    if (moy >= 14) return Colors.green.shade700;
    if (moy >= 10) return Colors.teal;
    return Colors.red.shade700;
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  // =========================================================================
  // Dialogue Ajouter / Modifier une Note
  // =========================================================================
  void _showNoteDialog({Note? existing}) {
    final codMatCtrl = TextEditingController(text: existing?.codMat ?? '');
    final nomMatCtrl = TextEditingController(text: existing?.nomMat ?? '');
    final coefCtrl = TextEditingController(text: existing != null ? existing.coef.toString() : '1.5');
    final tp1Ctrl = TextEditingController(text: existing?.tp1?.toString() ?? '');
    final tp2Ctrl = TextEditingController(text: existing?.tp2?.toString() ?? '');
    final dsCtrl = TextEditingController(text: existing?.ds?.toString() ?? '');
    final examCtrl = TextEditingController(text: existing?.examen?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          existing == null ? 'Ajouter une note de matière' : 'Modifier les notes',
          style: GoogleFonts.oswald(color: Colors.indigo),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: codMatCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Code Matière * (ex: AFCP, M012, SOA)',
                    prefixIcon: Icon(Icons.code),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nomMatCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom Matière (Optionnel)',
                    prefixIcon: Icon(Icons.book),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: coefCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Coefficient * (ex: 1.5, 2.0)',
                    prefixIcon: Icon(Icons.calculate),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Requis';
                    final d = double.tryParse(v.trim());
                    if (d == null || d <= 0) return 'Invalide';
                    return null;
                  },
                ),
                const Divider(height: 24),
                const Text(
                  'Notes (sur 20) — laissez vide si non applicable :',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: tp1Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'TP 1',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: tp2Ctrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'TP 2',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'DS (40%)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: examCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Examen (60%)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final note = Note(
                id: existing?.id,
                nce: _etudiant?.nce ?? '',
                codMat: codMatCtrl.text.trim().toUpperCase(),
                nomMat: nomMatCtrl.text.trim().isEmpty ? codMatCtrl.text.trim().toUpperCase() : nomMatCtrl.text.trim(),
                coef: double.parse(coefCtrl.text.trim()),
                tp1: double.tryParse(tp1Ctrl.text.trim()),
                tp2: double.tryParse(tp2Ctrl.text.trim()),
                ds: double.tryParse(dsCtrl.text.trim()),
                examen: double.tryParse(examCtrl.text.trim()),
              );

              existing == null ? _addNote(note) : _updateNote(note);
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

  void _confirmDelete(Note n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer suppression'),
        content: Text('Supprimer les notes de la matière ${n.codMat} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              if (n.id != null) _deleteNote(n.id!);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Widgets de construction UI
  // =========================================================================
  Widget _buildStudentCard() {
    final etud = _etudiant;
    if (etud == null) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo.shade100,
                  child: const Icon(Icons.school, size: 34, color: Colors.indigo),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        etud.fullName,
                        style: GoogleFonts.oswald(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'NCE : ${etud.nce}',
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Classe : ${etud.codClass.isNotEmpty ? etud.codClass : "Non assigné"}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_allEtudiants.length > 1) ...[
              const Divider(height: 24),
              DropdownButtonFormField<Etudiant>(
                value: _allEtudiants.any((e) => e.nce == etud.nce)
                    ? _allEtudiants.firstWhere((e) => e.nce == etud.nce)
                    : null,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Changer d\'étudiant',
                  prefixIcon: const Icon(Icons.switch_account, color: Colors.indigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                items: _allEtudiants
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text('${e.nce} – ${e.fullName} (${e.codClass})'),
                        ))
                    .toList(),
                onChanged: (newEtud) {
                  if (newEtud != null && newEtud.nce != _etudiant?.nce) {
                    setState(() {
                      _etudiant = newEtud;
                    });
                    _fetchNotes();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMoyenneBanner() {
    final moy = _moyenneGenerale;
    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _mentionColor.withOpacity(0.5), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MOYENNE GÉNÉRALE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _notes.isEmpty ? '-- / 20' : '${moy.toStringAsFixed(2)} / 20',
                  style: GoogleFonts.oswald(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _mentionColor,
                  ),
                ),
                Text(
                  'Total Coefs : ${_totalCoef.toStringAsFixed(1)}  |  ${_notes.length} matière(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _mentionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _mentionColor),
              ),
              child: Text(
                _mention,
                style: TextStyle(
                  color: _mentionColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesTable() {
    if (_notes.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text(
              'Aucune note enregistrée pour cet étudiant.',
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Détail des Matières & Notes',
              style: GoogleFonts.oswald(fontSize: 18, color: Colors.indigo),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(Colors.indigo.shade50),
              columnSpacing: 14,
              columns: [
                const DataColumn(
                  label: Text('Matière', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('Coef', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('TP1', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('TP2', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('DS (40%)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('Examen (60%)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const DataColumn(
                  label: Text('Moyenne', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (_isAdmin)
                  const DataColumn(
                    label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
              rows: _notes.map((n) {
                final moyMat = n.moyenneMatiere;
                final isPassed = moyMat >= 10.0;

                return DataRow(
                  cells: [
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(n.codMat, style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (n.nomMat.isNotEmpty && n.nomMat != n.codMat)
                            Text(
                              n.nomMat,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    DataCell(Text('${n.coef}')),
                    DataCell(Text(n.tp1 != null ? '${n.tp1}' : '-')),
                    DataCell(Text(n.tp2 != null ? '${n.tp2}' : '-')),
                    DataCell(Text(n.ds != null ? '${n.ds}' : '-')),
                    DataCell(Text(n.examen != null ? '${n.examen}' : '-')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isPassed ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isPassed ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          '${moyMat.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isPassed ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ),
                    if (_isAdmin)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                              tooltip: 'Modifier',
                              onPressed: () => _showNoteDialog(existing: n),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              tooltip: 'Supprimer',
                              onPressed: () => _confirmDelete(n),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relevé de Notes', style: GoogleFonts.oswald()),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _fetchNotes,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _buildStudentCard(),
                  const SizedBox(height: 14),
                  _buildMoyenneBanner(),
                  const SizedBox(height: 14),
                  _buildNotesTable(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: !_isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showNoteDialog(),
              backgroundColor: Colors.indigo,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Ajouter note (+)', style: TextStyle(color: Colors.white)),
            ),
    );
  }
}

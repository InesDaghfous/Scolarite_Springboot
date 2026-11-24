import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helper.dart';
import 'classe.dart';
import 'etudiant.dart';
import 'releve_notes_screen.dart';
import 'user.dart';

class EtudiantScreen extends StatefulWidget {
  final User? currentUser;
  const EtudiantScreen({super.key, this.currentUser});

  @override
  State<EtudiantScreen> createState() => _EtudiantScreenState();
}

class _EtudiantScreenState extends State<EtudiantScreen> {
  bool get _isAdmin => widget.currentUser?.isAdmin ?? true;
  // ── données ───────────────────────────────────────────────────────────────
  List<Classe> _classes = [];
  List<Etudiant> _etudiants = [];
  Classe? _selectedClasse;

  bool _loadingClasses = false;
  bool _loadingEtudiants = false;

  @override
  void initState() {
    super.initState();
    _fetchClasses();
  }

  // =========================================================================
  // Appels API
  // =========================================================================
  Future<void> _fetchClasses() async {
    setState(() => _loadingClasses = true);
    try {
      final res = await http.get(Uri.parse('$baseUrl/classes'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'classes');
        setState(() {
          _classes = list.map((e) => Classe.fromMap(e as Map<String, dynamic>)).toList();
        });
      } else {
        _showError('Erreur ${res.statusCode} lors du chargement des classes');
      }
    } catch (_) {
      _showError('Impossible de contacter le serveur Spring Boot');
    } finally {
      setState(() => _loadingClasses = false);
    }
  }

  Future<void> _fetchEtudiants(String codClass) async {
    setState(() {
      _loadingEtudiants = true;
      _etudiants = [];
    });
    try {
      // 1. Essai avec l'endpoint Spring Data REST défini dans EtudiantRepository :
      // /etudiants/search/findByClasseCodClass?codClass=...&projection=p1
      var res = await http.get(
        Uri.parse('$baseUrl/etudiants/search/findByClasseCodClass?codClass=$codClass&projection=p1'),
      );

      // 2. Si non trouvé (404), essai avec le format REST classique :
      if (res.statusCode != 200) {
        res = await http.get(Uri.parse('$baseUrl/etudiants/classe/$codClass'));
      }

      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        setState(() {
          _etudiants = list.map((e) => Etudiant.fromMap(e as Map<String, dynamic>)).toList();
        });
      } else {
        _showError('Erreur ${res.statusCode} chargement étudiants');
      }
    } catch (_) {
      _showError('Erreur de communication avec le serveur');
    } finally {
      setState(() => _loadingEtudiants = false);
    }
  }

  Future<void> _addEtudiant(Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/etudiants'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (_selectedClasse != null) {
          await _fetchEtudiants(_selectedClasse!.codClass);
        }
        _showSuccess('Étudiant ajouté ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _updateEtudiant(String nce, Map<String, dynamic> body) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/etudiants/$nce'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (res.statusCode == 200) {
        if (_selectedClasse != null) {
          await _fetchEtudiants(_selectedClasse!.codClass);
        }
        _showSuccess('Étudiant modifié ✔');
      } else {
        _showError('Erreur ${res.statusCode}');
      }
    } catch (_) {
      _showError('Erreur réseau');
    }
  }

  Future<void> _deleteEtudiant(String nce) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/etudiants/$nce'));
      if (res.statusCode == 200 || res.statusCode == 204) {
        if (_selectedClasse != null) {
          await _fetchEtudiants(_selectedClasse!.codClass);
        }
        _showSuccess('Étudiant supprimé ✔');
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  // =========================================================================
  // Dialogue Ajouter / Modifier
  // =========================================================================
  void _showEtudiantDialog({Etudiant? existing}) {
    final nceCtrl = TextEditingController(text: existing?.nce ?? '');
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final prenomCtrl = TextEditingController(text: existing?.prenom ?? '');
    final dateCtrl = TextEditingController(text: existing?.dateNais ?? '');
    final lieuCtrl = TextEditingController(text: existing?.lieuNais ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Modifier l\'étudiant' : 'Ajouter un étudiant',
          style: GoogleFonts.oswald(color: Colors.blue),
        ),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isEdit)
                  TextFormField(
                    controller: nceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'NCE / ID',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                  ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: nomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: prenomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Date de naissance',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime(2002),
                      firstDate: DateTime(1970),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      dateCtrl.text =
                          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: lieuCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lieu de naissance',
                    prefixIcon: Icon(Icons.location_on),
                    border: OutlineInputBorder(),
                  ),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);

              final body = <String, dynamic>{
                'nom': nomCtrl.text.trim(),
                'prenom': prenomCtrl.text.trim(),
                'dateNais': dateCtrl.text.trim(),
                'lieuNais': lieuCtrl.text.trim(),
              };

              // Association classe pour Spring Data REST / JPA
              if (int.tryParse(_selectedClasse!.codClass) != null) {
                body['classe'] = '$baseUrl/classes/${_selectedClasse!.codClass}';
              }

              isEdit
                  ? _updateEtudiant(existing.nce, body)
                  : _addEtudiant(body);
            },
            child: Text(
              isEdit ? 'Modifier' : 'Ajouter',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Etudiant e) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Supprimer ${e.nom} ${e.prenom} (${e.nce}) ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteEtudiant(e.nce);
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student management', style: GoogleFonts.oswald()),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recharger les classes',
            onPressed: _fetchClasses,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Sélection DropDownButton de la classe (demande du TP p.12) ────
          Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(14),
            child: _loadingClasses
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Classe>(
                    value: _selectedClasse,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Classe : Code Classe',
                      border: OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.class_, color: Colors.blue),
                    ),
                    hint: Text(_classes.isEmpty
                        ? 'Aucune classe trouvée (Actualisez)'
                        : 'Choisir une classe (${_classes.length})'),
                    items: _classes
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text('${c.nomClass} (Code: ${c.codClass})'),
                            ))
                        .toList(),
                    onChanged: _classes.isEmpty
                        ? null
                        : (c) {
                            setState(() => _selectedClasse = c);
                            if (c != null) _fetchEtudiants(c.codClass);
                          },
                  ),
          ),

          // ── Compteur ───────────────────────────────────────────────────
          if (_selectedClasse != null && !_loadingEtudiants)
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${_etudiants.length} étudiant(s) trouvé(s) pour ${_selectedClasse!.nomClass}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),

          // ── Liste des étudiants ────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: !_isAdmin
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                if (_selectedClasse == null) {
                  _showError('Veuillez d\'abord sélectionner une classe dans la liste.');
                } else {
                  _showEtudiantDialog();
                }
              },
              backgroundColor: Colors.blue,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text('Ajouter étudiant', style: TextStyle(color: Colors.white)),
            ),
    );
  }

  Widget _buildBody() {
    if (_selectedClasse == null) {
      return const Center(
        child: Text(
          'Veuillez sélectionner une classe\npour afficher ses étudiants',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }
    if (_loadingEtudiants) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_etudiants.isEmpty) {
      return const Center(
        child: Text('Aucun étudiant dans cette classe',
            style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _etudiants.length,
      itemBuilder: (ctx, i) {
        final e = _etudiants[i];
        return Card(
          elevation: 3,
          margin: const EdgeInsets.symmetric(vertical: 5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReleveNotesScreen(
                    etudiant: e,
                    currentUser: widget.currentUser,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                e.nom.isNotEmpty ? e.nom[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${e.nom} ${e.prenom}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NCE/ID : ${e.nce}',
                    style: const TextStyle(color: Colors.grey)),
                if (e.dateNais != null && e.dateNais!.isNotEmpty)
                  Text('Date Nais : ${e.dateNais}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                if (e.lieuNais != null && e.lieuNais!.isNotEmpty)
                  Text('Lieu : ${e.lieuNais}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Relevé de notes',
                  icon: const Icon(Icons.assignment, color: Colors.indigo),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReleveNotesScreen(
                          etudiant: e,
                          currentUser: widget.currentUser,
                        ),
                      ),
                    );
                  },
                ),
                if (_isAdmin) ...[
                  IconButton(
                    tooltip: 'Modifier',
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEtudiantDialog(existing: e),
                  ),
                  IconButton(
                    tooltip: 'Supprimer',
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(e),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

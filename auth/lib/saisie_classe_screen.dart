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
import 'user.dart';


class SaisieClasseScreen extends StatefulWidget {
  final User? currentUser;
  const SaisieClasseScreen({super.key, this.currentUser});

  @override
  State<SaisieClasseScreen> createState() => _SaisieClasseScreenState();
}

class _SaisieClasseScreenState extends State<SaisieClasseScreen> {
  
  List<Departement> _departements = [];
  List<Classe> _allClasses = [];
  List<Classe> _classes = [];
  List<Etudiant> _etudiants = [];

  
  Departement? _selectedDept;
  Classe? _selectedClasse;
  String _codMat = '';
  String _nomMat = '';
  String _dateA = '';
  double _nha = 1.5;

  // absences deja enregistres
  final Map<String, Absence> _existing = {};
  // ── Étudiants absents
  final Set<String> _selectedNce = {};


  final Map<String, double> _customNha = {};

  bool _loadingDepts = false;
  bool _loadingClasses = false;
  bool _loadingEtudiants = false;
  bool _loadingExisting = false;
  bool _saving = false;


  final _codMatCtrl = TextEditingController();
  final _nomMatCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _nhaCtrl = TextEditingController(text: '1.5');


  final List<Map<String, String>> _matieres = [
    {'code': 'AFCP', 'nom': 'Architecture & Frameworks'},
    {'code': 'SOA', 'nom': 'Services Web & Microservices'},
    {'code': 'BD', 'nom': 'Bases de Données Avancées'},
    {'code': 'ALGO', 'nom': 'Algorithmique Avancée'},
    {'code': 'M012', 'nom': 'Atelier Développement Web'},
    {'code': 'RESX', 'nom': 'Réseaux & Sécurité'},
    {'code': 'SYS', 'nom': 'Systèmes d\'exploitation'},
    {'code': 'MATH', 'nom': 'Mathématiques'},
    {'code': 'ANGL', 'nom': 'Anglais'},
    {'code': 'MGMT', 'nom': 'Management'},
  ];

  @override
  void initState() {
    super.initState();
    _fetchDepartementsAndClasses();
  }

  @override
  void dispose() {
    _codMatCtrl.dispose();
    _nomMatCtrl.dispose();
    _dateCtrl.dispose();
    _nhaCtrl.dispose();
    super.dispose();
  }



  Future<void> _fetchDepartementsAndClasses() async {
    setState(() {
      _loadingDepts = true;
      _loadingClasses = true;
    });
    try {
      final resDepts = await http.get(Uri.parse('$baseUrl/departements'));
      final resClasses = await http.get(Uri.parse('$baseUrl/classes'));

      if (resDepts.statusCode == 200) {
        final list = parseHalList(resDepts.body, 'departements');
        _departements = list
            .map((e) => Departement.fromMap(e as Map<String, dynamic>))
            .toList();
      }
      if (resClasses.statusCode == 200) {
        final list = parseHalList(resClasses.body, 'classes');
        _allClasses = list
            .map((e) => Classe.fromMap(e as Map<String, dynamic>))
            .toList();
        _classes = List.from(_allClasses);
      }
    } catch (e) {
      _showError('Erreur de connexion au serveur');
    } finally {
      if (mounted) {
        setState(() {
          _loadingDepts = false;
          _loadingClasses = false;
        });
      }
    }
  }

  Future<void> _fetchEtudiants(String codClass) async {
    setState(() {
      _loadingEtudiants = true;
      _etudiants = [];
      _selectedNce.clear();
      _existing.clear();
      _customNha.clear();
    });
    try {
      final res = await http.get(Uri.parse('$baseUrl/etudiants'));
      if (res.statusCode == 200) {
        final list = parseHalList(res.body, 'etudiants');
        final all = list
            .map((e) => Etudiant.fromMap(e as Map<String, dynamic>))
            .toList();
        _etudiants = all.where((e) => e.codClass == codClass).toList();
        // Après avoir chargé les étudiants, charger les absences existantes
        if (_codMat.isNotEmpty && _dateA.isNotEmpty) {
          await _fetchExistingAbsences();
        }
      }
    } catch (_) {
      _showError('Impossible de charger les étudiants');
    } finally {
      if (mounted) setState(() => _loadingEtudiants = false);
    }
  }

  Future<void> _fetchExistingAbsences() async {
    if (_selectedClasse == null || _codMat.isEmpty || _dateA.isEmpty) return;
    setState(() => _loadingExisting = true);
    try {
      final uri = Uri.parse(
          '$baseUrl/absences/classe/${_selectedClasse!.codClass}/matiere/$_codMat/date/$_dateA');
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final raw = json.decode(res.body);
        List<dynamic> items = [];
        if (raw is List) {
          items = raw;
        } else if (raw is Map && raw.containsKey('_embedded')) {
          final embedded = raw['_embedded'] as Map;
          items = embedded.values.first as List;
        }
        _existing.clear();
        _selectedNce.clear();
        for (final item in items) {
          final a = Absence.fromMap(item as Map<String, dynamic>);
          if (a.nce.isNotEmpty) {
            _existing[a.nce] = a;
            _selectedNce.add(a.nce);
            _customNha[a.nce] = a.nha;
          }
        }
      }
    } catch (_) {
      // pas grave, on repart de zéro
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  

  Future<void> _saveAll() async {
    if (_selectedClasse == null || _codMat.isEmpty || _dateA.isEmpty) {
      _showError('Veuillez remplir tous les champs obligatoires');
      return;
    }
    setState(() => _saving = true);

    int saved = 0;
    int deleted = 0;
    int errors = 0;

    // 1. Étudiants désormais NON cochés mais qui avaient une absence → supprimer
    for (final nce in _existing.keys) {
      if (!_selectedNce.contains(nce)) {
        final a = _existing[nce]!;
        if (a.id != null) {
          try {
            final res =
                await http.delete(Uri.parse('$baseUrl/absences/${a.id}'));
            if (res.statusCode == 200 || res.statusCode == 204) {
              deleted++;
            } else {
              errors++;
            }
          } catch (_) {
            errors++;
          }
        }
      }
    }

    // 2. Étudiants cochés → créer ou mettre à jour
    final List<Map<String, dynamic>> toCreate = [];
    final List<Absence> toUpdate = [];

    for (final nce in _selectedNce) {
      final hours = _customNha[nce] ?? _nha;
      if (_existing.containsKey(nce)) {
        // déjà existant → mettre à jour si les heures ont changé
        final existing = _existing[nce]!;
        if (existing.nha != hours) {
          toUpdate.add(Absence(
            id: existing.id,
            codMat: _codMat,
            nce: nce,
            dateA: _dateA,
            nha: hours,
          ));
        } else {
          saved++; // rien à changer
        }
      } else {
        // nouvelle absence
        toCreate.add({
          'codMat': _codMat,
          'nce': nce,
          'dateA': _dateA,
          'nha': hours,
        });
      }
    }

    // Mises à jour
    for (final a in toUpdate) {
      try {
        final res = await http.put(
          Uri.parse('$baseUrl/absences/${a.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(a.toMap()),
        );
        if (res.statusCode == 200) {
          saved++;
        } else {
          errors++;
        }
      } catch (_) {
        errors++;
      }
    }

    // Créations via batch
    if (toCreate.isNotEmpty) {
      try {
        final res = await http.post(
          Uri.parse('$baseUrl/absences/batch'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(toCreate),
        );
        if (res.statusCode == 200 || res.statusCode == 201) {
          saved += toCreate.length;
        } else {
          // fallback : une par une
          for (final body in toCreate) {
            try {
              final r = await http.post(
                Uri.parse('$baseUrl/absences'),
                headers: {'Content-Type': 'application/json'},
                body: json.encode(body),
              );
              if (r.statusCode == 200 || r.statusCode == 201) {
                saved++;
              } else {
                errors++;
              }
            } catch (_) {
              errors++;
            }
          }
        }
      } catch (_) {
        errors++;
      }
    }

    setState(() => _saving = false);

    if (!mounted) return;

    final msg =
        '✅ $saved absence(s) enregistrée(s)${deleted > 0 ? ", $deleted supprimée(s)" : ""}${errors > 0 ? " — ⚠️ $errors erreur(s)" : ""}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: errors > 0 ? Colors.orange : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );

    // Recharger pour refléter l'état réel
    await _fetchExistingAbsences();
  }

  

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  InputDecoration _dropDecor(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.purple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );

  // Affiche un picker de date et met à jour _dateA et le contrôleur
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      setState(() {
        _dateA = formatted;
        _dateCtrl.text = formatted;
      });
      // Recharger les absences existantes si tout est rempli
      if (_selectedClasse != null && _codMat.isNotEmpty) {
        await _fetchExistingAbsences();
      }
    }
  }

  void _selectMatiere(Map<String, String> m) {
    setState(() {
      _codMat = m['code']!;
      _nomMat = m['nom']!;
      _codMatCtrl.text = m['code']!;
      _nomMatCtrl.text = m['nom']!;
    });
    if (_selectedClasse != null && _dateA.isNotEmpty) {
      _fetchExistingAbsences();
    }
  }

  void _toggleEtudiant(String nce, bool checked) {
    setState(() {
      if (checked) {
        _selectedNce.add(nce);
        _customNha.putIfAbsent(nce, () => _nha);
      } else {
        _selectedNce.remove(nce);
      }
    });
  }

  void _toggleAll(bool check) {
    setState(() {
      if (check) {
        _selectedNce.addAll(_etudiants.map((e) => e.nce));
        for (final e in _etudiants) {
          _customNha.putIfAbsent(e.nce, () => _nha);
        }
      } else {
        // Seulement décocher ceux qui ne sont pas déjà en base
        for (final e in _etudiants) {
          if (!_existing.containsKey(e.nce)) {
            _selectedNce.remove(e.nce);
          }
        }
      }
    });
  }

  // =========================================================================
  // Build
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final allChecked =
        _etudiants.isNotEmpty && _etudiants.every((e) => _selectedNce.contains(e.nce));
    final absentCount = _selectedNce.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('Saisie absences par classe', style: GoogleFonts.oswald()),
        backgroundColor: const Color(0xFF8E24AA),
        foregroundColor: Colors.white,
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          else
            IconButton(
              icon: const Icon(Icons.save_rounded),
              tooltip: 'Enregistrer',
              onPressed: _etudiants.isEmpty ? null : _saveAll,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFicheCard(),
            const SizedBox(height: 14),
            _buildMatiereCard(),
            const SizedBox(height: 14),
            if (_etudiants.isNotEmpty || _loadingEtudiants)
              _buildEtudiantsCard(allChecked, absentCount),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: _etudiants.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _saving ? null : _saveAll,
              backgroundColor: const Color(0xFF8E24AA),
              icon: const Icon(Icons.save, color: Colors.white),
              label: Text(
                '$absentCount absent(s) — Enregistrer',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

 
  Widget _buildFicheCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📋 Fiche de séance',
                style: GoogleFonts.oswald(fontSize: 18, color: Colors.purple.shade800)),
            const SizedBox(height: 14),

            // Département
            if (_loadingDepts)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<Departement?>(
                value: _selectedDept,
                isExpanded: true,
                decoration: _dropDecor('Département', Icons.business),
                hint: const Text('Tous les départements'),
                items: [
                  const DropdownMenuItem<Departement?>(
                    value: null,
                    child: Text('--- Tous les départements ---'),
                  ),
                  ..._departements.map((d) => DropdownMenuItem<Departement?>(
                        value: d,
                        child: Text('${d.codDept} – ${d.nomDept}'),
                      )),
                ],
                onChanged: (d) {
                  setState(() {
                    _selectedDept = d;
                    _selectedClasse = null;
                    _etudiants = [];
                    _selectedNce.clear();
                    _existing.clear();
                    if (d != null) {
                      _classes = _allClasses
                          .where((c) => c.codDept == d.codDept)
                          .toList();
                    } else {
                      _classes = List.from(_allClasses);
                    }
                  });
                },
              ),

            const SizedBox(height: 10),

            // Classe
            if (_loadingClasses)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<Classe?>(
                value: _selectedClasse,
                isExpanded: true,
                decoration: _dropDecor('Classe *', Icons.class_),
                hint: Text(_classes.isEmpty
                    ? 'Aucune classe disponible'
                    : 'Sélectionner une classe (${_classes.length})'),
                items: _classes
                    .map((c) => DropdownMenuItem<Classe?>(
                          value: c,
                          child: Text('${c.codClass} – ${c.nomClass}'),
                        ))
                    .toList(),
                onChanged: (c) {
                  setState(() {
                    _selectedClasse = c;
                    _etudiants = [];
                    _selectedNce.clear();
                    _existing.clear();
                  });
                  if (c != null) _fetchEtudiants(c.codClass);
                },
              ),

            const SizedBox(height: 10),

            // Date
            TextFormField(
              controller: _dateCtrl,
              decoration: _dropDecor('Date de la séance * (JJ-MM-AAAA)', Icons.calendar_today)
                  .copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.date_range, color: Colors.purple),
                  onPressed: _pickDate,
                ),
              ),
              onChanged: (v) {
                setState(() => _dateA = v.trim());
                if (_selectedClasse != null && _codMat.isNotEmpty && v.trim().length >= 8) {
                  _fetchExistingAbsences();
                }
              },
            ),

            const SizedBox(height: 10),

            // Heures par défaut
            TextFormField(
              controller: _nhaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _dropDecor('Nb heures d\'absence par défaut *', Icons.timer),
              onChanged: (v) {
                final d = double.tryParse(v);
                if (d != null) setState(() => _nha = d);
              },
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildMatiereCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📚 Matière',
                style: GoogleFonts.oswald(fontSize: 18, color: Colors.indigo.shade800)),
            const SizedBox(height: 10),

            // Boutons rapides de matières
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _matieres
                  .map((m) => FilterChip(
                        label: Text(m['code']!),
                        tooltip: m['nom'],
                        selected: _codMat == m['code'],
                        selectedColor: Colors.indigo.shade100,
                        checkmarkColor: Colors.indigo,
                        onSelected: (_) => _selectMatiere(m),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 10),

            // Code matière (saisie libre)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _codMatCtrl,
                    decoration: _dropDecor('Code matière *', Icons.code),
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (v) {
                      setState(() => _codMat = v.trim().toUpperCase());
                      if (_selectedClasse != null && _dateA.isNotEmpty && v.trim().length >= 2) {
                        _fetchExistingAbsences();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _nomMatCtrl,
                    decoration: _dropDecor('Nom matière', Icons.book),
                    onChanged: (v) => setState(() => _nomMat = v.trim()),
                  ),
                ),
              ],
            ),

            if (_codMat.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                    const SizedBox(width: 6),
                    Text(
                      'Matière sélectionnée : $_codMat${_nomMat.isNotEmpty ? " – $_nomMat" : ""}',
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Liste des étudiants avec cases à cocher ────────────────────────────
  Widget _buildEtudiantsCard(bool allChecked, int absentCount) {
    if (_loadingEtudiants || _loadingExisting) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final classeInfo = _selectedClasse != null
        ? '${_selectedClasse!.codClass} – ${_selectedClasse!.nomClass}'
        : '';

    // Récap en-tête
    final totalEtud = _etudiants.length;
    final pct = totalEtud > 0 ? (absentCount / totalEtud * 100).toStringAsFixed(0) : '0';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Entête ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '👥 Étudiants – $classeInfo',
                        style: GoogleFonts.oswald(
                            fontSize: 17, color: Colors.purple.shade800),
                      ),
                    ),
                    // Cocher tout / Décocher tout
                    TextButton.icon(
                      onPressed: () => _toggleAll(!allChecked),
                      icon: Icon(
                        allChecked
                            ? Icons.deselect
                            : Icons.select_all,
                        size: 18,
                        color: Colors.purple,
                      ),
                      label: Text(
                        allChecked ? 'Tout décocher' : 'Tout cocher',
                        style: const TextStyle(color: Colors.purple, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Info séance
                if (_codMat.isNotEmpty && _dateA.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, size: 16, color: Colors.indigo),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Matière : $_codMat${_nomMat.isNotEmpty ? " ($_nomMat)" : ""}  |  Date : $_dateA  |  ${_nha}h/séance',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.indigo,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 6),

                // Compteur absents
                LinearProgressIndicator(
                  value: totalEtud > 0 ? absentCount / totalEtud : 0,
                  color: absentCount > totalEtud * 0.5
                      ? Colors.red
                      : Colors.orange,
                  backgroundColor: Colors.grey.shade200,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 4),
                Text(
                  '$absentCount absent(s) sur $totalEtud étudiant(s)   ($pct%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: absentCount > 0 ? Colors.red.shade700 : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // ── Ligne d'en-tête du tableau ───────────────────────────────────
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const SizedBox(width: 32),
                const Expanded(
                  flex: 3,
                  child: Text('NCE / Nom',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 6),
                const Text('Heures',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(width: 10),
                const Text('Absent',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Liste des étudiants ──────────────────────────────────────────
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _etudiants.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = _etudiants[i];
              final isAbsent = _selectedNce.contains(e.nce);
              final hours = _customNha[e.nce] ?? _nha;
              final alreadySaved = _existing.containsKey(e.nce);

              return Container(
                color: isAbsent
                    ? (alreadySaved
                        ? Colors.red.shade50
                        : Colors.orange.shade50)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      // Numéro
                      SizedBox(
                        width: 24,
                        child: Text(
                          '${i + 1}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nom étudiant
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.nom} ${e.prenom}',
                              style: TextStyle(
                                fontWeight: isAbsent
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isAbsent
                                    ? Colors.red.shade800
                                    : Colors.black87,
                              ),
                            ),
                            Text(
                              e.nce,
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey.shade600),
                            ),
                            if (alreadySaved)
                              const Text(
                                '✔ déjà enregistré',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.green),
                              ),
                          ],
                        ),
                      ),

                     
                      if (isAbsent) ...[
                        SizedBox(
                          width: 60,
                          child: TextFormField(
                            initialValue: hours.toString(),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 6),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6)),
                              suffixText: 'h',
                            ),
                            onChanged: (v) {
                              final d = double.tryParse(v);
                              if (d != null) {
                                setState(() => _customNha[e.nce] = d);
                              }
                            },
                          ),
                        ),
                      ] else
                        const SizedBox(width: 60),

                      const SizedBox(width: 10),

                      // Case à cocher
                      Checkbox(
                        value: isAbsent,
                        activeColor: Colors.red,
                        onChanged: (v) => _toggleEtudiant(e.nce, v ?? false),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 8),

          // ── Bouton Enregistrer en bas ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(
                  _saving
                      ? 'Enregistrement...'
                      : 'Enregistrer ($absentCount absent(s))',
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'api_helper.dart';
import 'classe.dart';
import 'etudiant.dart';
import 'user.dart';

class ClasseMaxEtudiantsScreen extends StatefulWidget {
  final User? currentUser;
  const ClasseMaxEtudiantsScreen({super.key, this.currentUser});

  @override
  State<ClasseMaxEtudiantsScreen> createState() =>
      _ClasseMaxEtudiantsScreenState();
}

class _ClasseMaxEtudiantsScreenState extends State<ClasseMaxEtudiantsScreen> {
  bool _loading = true;
  bool _updating = false;
  String? _errorMessage;

  List<Classe> _classes = [];
  List<Etudiant> _etudiants = [];

  // Classe ayant le plus grand nombre d'étudiants dans la table Etudiant
  Classe? _maxClasse;
  int _maxCount = 0;
  List<Etudiant> _maxClasseEtudiants = [];

  // Comptage direct de chaque classe dans la table Etudiant
  Map<String, int> _countsInEtudiantTable = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // =========================================================================
  // Chargement des données et calcul strict basé sur la table Etudiant
  // =========================================================================
  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Récupération de toutes les classes et de tous les étudiants
      final resClasses = await http.get(Uri.parse('$baseUrl/classes'));
      final resEtudiants = await http.get(Uri.parse('$baseUrl/etudiants'));

      if (resClasses.statusCode != 200 || resEtudiants.statusCode != 200) {
        throw Exception('Erreur de communication avec le serveur backend');
      }

      final rawClasses = parseHalList(resClasses.body, 'classes');
      final rawEtudiants = parseHalList(resEtudiants.body, 'etudiants');

      final classes = rawClasses
          .map((c) => Classe.fromMap(c as Map<String, dynamic>))
          .toList();
      final etudiants = rawEtudiants
          .map((e) => Etudiant.fromMap(e as Map<String, dynamic>))
          .toList();

      // 2. Comptage strict des lignes dans la table Etudiant
      // NOTE IMPORTANTE : Ne pas utiliser la colonne NbrEtud de la table Classe !
      final Map<String, int> counts = {};
      final Map<String, List<Etudiant>> groupedStudents = {};

      for (final c in classes) {
        counts[c.codClass] = 0;
        groupedStudents[c.codClass] = [];
      }

      for (final e in etudiants) {
        if (e.codClass.isNotEmpty) {
          counts[e.codClass] = (counts[e.codClass] ?? 0) + 1;
          groupedStudents.putIfAbsent(e.codClass, () => []).add(e);
        }
      }

      // 3. Trouver la classe possédant le plus grand nombre d'étudiants
      Classe? topClasse;
      int highest = -1;

      for (final c in classes) {
        final count = counts[c.codClass] ?? 0;
        if (count > highest) {
          highest = count;
          topClasse = c;
        }
      }

      setState(() {
        _classes = classes;
        _etudiants = etudiants;
        _countsInEtudiantTable = counts;
        _maxClasse = topClasse;
        _maxCount = highest >= 0 ? highest : 0;
        _maxClasseEtudiants =
            topClasse != null ? (groupedStudents[topClasse.codClass] ?? []) : [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Impossible de charger les données : $e';
        _loading = false;
      });
    }
  }

  // =========================================================================
  // Mise à jour de la colonne NbrEtud de cette classe spécifique
  // =========================================================================
  Future<void> _updateNbrEtudForMaxClasse() async {
    if (_maxClasse == null) return;

    final targetClasse = _maxClasse!;
    final newNbr = _maxCount;

    setState(() => _updating = true);

    try {
      // 1. Essayer d'abord l'endpoint direct de synchronisation
      var res = await http.put(
        Uri.parse('$baseUrl/classes/${targetClasse.codClass}/sync-effectif'),
      );

      // 2. Si non supporté (404/405), fallback sur le PUT classique de la classe
      if (res.statusCode != 200 && res.statusCode != 201) {
        final updatePayload = {
          if (targetClasse.id != null) 'id': targetClasse.id,
          'codClass': targetClasse.codClass,
          'nomClass': targetClasse.nomClass,
          'nbreEtud': newNbr,
          'nbrEtud': newNbr,
          'codDept': targetClasse.codDept,
        };

        final idToUse = targetClasse.id?.toString() ?? targetClasse.codClass;
        res = await http.put(
          Uri.parse('$baseUrl/classes/$idToUse'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(updatePayload),
        );
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✔ Colonne NbrEtud de la classe ${targetClasse.codClass} mise à jour avec succès : $newNbr étudiants',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
        // Recharger pour refléter la valeur persistée en base
        await _loadData();
      } else {
        throw Exception('Erreur serveur code HTTP ${res.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour : $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  // =========================================================================
  // Interface graphique
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Classe avec le plus d\'étudiants',
          style: GoogleFonts.oswald(),
        ),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loading ? null : _loadData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            SizedBox(height: 16),
            Text('Comptage des étudiants dans la table Etudiant...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_maxClasse == null) {
      return const Center(
        child: Text('Aucune classe trouvée dans la base de données.'),
      );
    }

    final top = _maxClasse!;
    final isSynchronized = top.nbrEtud == _maxCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Note explicative sur le mode de calcul ──────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Calcul strict : Le nombre d\'étudiants est calculé en comptant les lignes réelles dans la table "Etudiant" '
                    '(sans utiliser la colonne NbrEtud de la table Classe).',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Carte principale : La classe gagnante ──────────────────────────
          _buildWinnerCard(top, isSynchronized),
          const SizedBox(height: 20),

          // ── Bouton de mise à jour de la colonne NbrEtud ─────────────────────
          _buildUpdateButton(top, isSynchronized),
          const SizedBox(height: 20),

          // ── Liste détaillée des étudiants de cette classe ──────────────────
          _buildStudentsListCard(top),
          const SizedBox(height: 20),

          // ── Tableau comparatif de toutes les classes ───────────────────────
          _buildAllClassesCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Carte principale affichant la classe avec le plus d'étudiants ──────────
  Widget _buildWinnerCard(Classe top, bool isSynchronized) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF59E0B), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.amber.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB45309),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'CLASSE AVEC LE PLUS D\'ÉTUDIANTS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${top.codClass} - ${top.nomClass}',
                        style: GoogleFonts.oswald(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E3A8A),
                        ),
                      ),
                      if (top.codDept.isNotEmpty)
                        Text(
                          'Département : ${top.codDept}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 30),

            // Comparatif des deux valeurs
            Row(
              children: [
                // 1. Valeur réelle comptée dans la table Etudiant
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.shade300, width: 1.5),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Compte réel (Table Etudiant)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_maxCount',
                          style: GoogleFonts.oswald(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const Text(
                          'étudiant(s)',
                          style: TextStyle(fontSize: 12, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // 2. Valeur actuelle dans la colonne NbrEtud de la table Classe
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSynchronized
                          ? Colors.grey.shade100
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSynchronized
                            ? Colors.grey.shade300
                            : Colors.orange.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Colonne NbrEtud (Table Classe)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${top.nbrEtud}',
                          style: GoogleFonts.oswald(
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            color: isSynchronized
                                ? Colors.black87
                                : Colors.orange.shade800,
                          ),
                        ),
                        const Text(
                          'valeur enregistrée',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Statut de synchronisation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSynchronized ? Colors.green.shade100 : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSynchronized ? Icons.check_circle : Icons.warning_amber,
                    color: isSynchronized
                        ? Colors.green.shade800
                        : Colors.orange.shade900,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isSynchronized
                        ? 'Colonne NbrEtud synchronisée avec la table Etudiant'
                        : 'Décalage détecté : NbrEtud = ${top.nbrEtud} vs Table Etudiant = $_maxCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSynchronized
                          ? Colors.green.shade900
                          : Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bouton pour mettre à jour la colonne NbrEtud de cette classe ────────────
  Widget _buildUpdateButton(Classe top, bool isSynchronized) {
    return ElevatedButton.icon(
      onPressed: _updating ? null : _updateNbrEtudForMaxClasse,
      icon: _updating
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
            )
          : const Icon(Icons.sync, color: Colors.white, size: 24),
      label: Text(
        _updating
            ? 'Mise à jour en cours...'
            : 'Mettre à jour NbrEtud de ${top.codClass} à $_maxCount',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 4,
      ),
    );
  }

  // ── Liste des étudiants de cette classe ──────────────────────────────────
  Widget _buildStudentsListCard(Classe top) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  'Étudiants enregistrés dans ${top.codClass} (${_maxClasseEtudiants.length})',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_maxClasseEtudiants.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Aucun étudiant trouvé dans la table Etudiant pour cette classe.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _maxClasseEtudiants.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final etud = _maxClasseEtudiants[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '${etud.nom} ${etud.prenom}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('NCE : ${etud.nce}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        top.codClass,
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Tableau récapitulatif de toutes les classes ────────────────────────────
  Widget _buildAllClassesCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.table_chart, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 8),
                Text(
                  'Toutes les classes : Table Etudiant vs Colonne NbrEtud',
                  style: GoogleFonts.oswald(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(Colors.blue.shade50),
                columns: const [
                  DataColumn(
                    label: Text('Classe',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Département',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Compte Table Etudiant',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('Colonne NbrEtud (Classe)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  DataColumn(
                    label: Text('État',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                rows: _classes.map((c) {
                  final count = _countsInEtudiantTable[c.codClass] ?? 0;
                  final isWinner = _maxClasse?.codClass == c.codClass;
                  final isSynced = c.nbrEtud == count;

                  return DataRow(
                    color: isWinner
                        ? WidgetStateProperty.all(Colors.amber.shade50)
                        : null,
                    cells: [
                      DataCell(
                        Row(
                          children: [
                            if (isWinner) ...[
                              const Icon(Icons.emoji_events,
                                  color: Colors.amber, size: 18),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              c.codClass,
                              style: TextStyle(
                                fontWeight: isWinner
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      DataCell(Text(c.codDept.isNotEmpty ? c.codDept : '-')),
                      DataCell(
                        Text(
                          '$count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isWinner ? Colors.green.shade800 : null,
                          ),
                        ),
                      ),
                      DataCell(Text('${c.nbrEtud}')),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSynced
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSynced
                                  ? Colors.green.shade300
                                  : Colors.orange.shade300,
                            ),
                          ),
                          child: Text(
                            isSynced ? 'Synchro ✔' : 'Décalé (${c.nbrEtud} != $count)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSynced
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

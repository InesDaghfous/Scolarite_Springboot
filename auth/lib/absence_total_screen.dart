import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'absence.dart';
import 'classe.dart';
import 'departement.dart';
import 'etudiant.dart';

class AbsenceTotalScreen extends StatelessWidget {
  final Etudiant etudiant;
  final List<Absence> absences;
  final Classe classe;
  final Departement departement;

  const AbsenceTotalScreen({
    super.key,
    required this.etudiant,
    required this.absences,
    required this.classe,
    required this.departement,
  });

  List<MapEntry<String, double>> get _totaux {
    final map = <String, double>{};
    for (final a in absences) {
      map[a.codMat] = (map[a.codMat] ?? 0) + a.nha;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  // =========================================================================
  // Build
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final totaux = _totaux;
    final maxVal =
        totaux.isEmpty ? 1.0 : totaux.first.value;

    return Scaffold(
      appBar: AppBar(
        title: Text('Total des Absences', style: GoogleFonts.oswald()),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Fiche étudiant ─────────────────────────────────────────
            _infoCard(),
            const SizedBox(height: 14),

            // ── Tableau des totaux ─────────────────────────────────────
            _totalTable(totaux),
            const SizedBox(height: 14),

            // ── Graphique à barres ──────────────────────────────────────
            _chartCard(totaux, maxVal),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Fiche étudiant
  // =========================================================================
  Widget _infoCard() {
    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Classe',
                '${classe.codClass} – ${classe.nomClass}'),
            _row('Département',
                '${departement.codDept} – ${departement.nomDept}'),
            const Divider(height: 20),
            _row('Étudiant (NCE)', etudiant.nce),
            _row('Nom', etudiant.nom),
            _row('Prénom', etudiant.prenom),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                '$label :',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
            ),
            Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 15)),
            ),
          ],
        ),
      );

  // =========================================================================
  // Tableau récapitulatif
  // =========================================================================
  Widget _totalTable(List<MapEntry<String, double>> totaux) {
    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Récapitulatif par matière',
              style: GoogleFonts.oswald(
                  fontSize: 18, color: Colors.purple),
            ),
          ),
          if (totaux.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Aucune donnée',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            DataTable(
              headingRowColor:
                  WidgetStateProperty.all(Colors.purple.shade50),
              columnSpacing: 24,
              columns: const [
                DataColumn(
                    label: Text('Code Matière',
                        style:
                            TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(
                    label: Text('Total NHA',
                        style:
                            TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: totaux
                  .map((e) => DataRow(cells: [
                        DataCell(
                          Chip(
                            label: Text(e.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12)),
                            backgroundColor: Colors.purple,
                          ),
                        ),
                        DataCell(Text(
                          '${e.value} h',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        )),
                      ]))
                  .toList(),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // Graphique à barres (CustomPaint – sans dépendance externe)
  // =========================================================================
  Widget _chartCard(
      List<MapEntry<String, double>> totaux, double maxVal) {
    if (totaux.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Pas de données à représenter',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.orange,
      Colors.teal,
      Colors.red,
      Colors.green,
      Colors.indigo,
      Colors.amber,
    ];

    const chartHeight = 200.0;

    return Card(
      elevation: 4,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Graphique des absences par matière',
              style: GoogleFonts.oswald(
                  fontSize: 18, color: Colors.purple),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: chartHeight + 50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // ── Axe Y ─────────────────────────────────────────
                  Column(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          '${maxVal.toStringAsFixed(1)}h',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey)),
                      Text(
                          '${(maxVal / 2).toStringAsFixed(1)}h',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey)),
                      const Text('0h',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey)),
                      const SizedBox(height: 42),
                    ],
                  ),
                  const SizedBox(width: 6),

                  // ── Barres ────────────────────────────────────────
                  Expanded(
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.end,
                      mainAxisAlignment:
                          MainAxisAlignment.spaceEvenly,
                      children: totaux.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final e = entry.value;
                        final barHeight = maxVal > 0
                            ? (e.value / maxVal) * chartHeight
                            : 0.0;
                        final color = colors[idx % colors.length];

                        return Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 4),
                            child: Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.end,
                              children: [
                                // valeur au-dessus
                                Text(
                                  '${e.value}h',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight:
                                          FontWeight.bold),
                                  textAlign:
                                      TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                // barre
                                AnimatedContainer(
                                  duration: const Duration(
                                      milliseconds: 600),
                                  curve: Curves.easeOut,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius:
                                        const BorderRadius
                                            .vertical(
                                      top: Radius.circular(6),
                                    ),
                                  ),
                                ),
                                // ligne de base
                                Container(
                                    height: 2,
                                    color: Colors.grey
                                        .shade300),
                                const SizedBox(height: 4),
                                // label
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight:
                                        FontWeight.bold,
                                    color: color,
                                  ),
                                  textAlign:
                                      TextAlign.center,
                                  overflow:
                                      TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Légende ───────────────────────────────────────────────
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: totaux.asMap().entries.map((entry) {
                final color = colors[entry.key % colors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                                BorderRadius.circular(3))),
                    const SizedBox(width: 4),
                    Text(entry.value.key,
                        style: const TextStyle(fontSize: 12)),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}


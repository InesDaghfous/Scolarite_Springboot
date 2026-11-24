import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'user.dart';
import 'absence_screen.dart';
import 'etudiant_screen.dart';
import 'mes_absences_screen.dart';
import 'releve_notes_screen.dart';
import 'saisie_classe_screen.dart';
import 'classe_max_etudiants_screen.dart';
import 'login.dart';

class Dashboard extends StatelessWidget {
  final User user;
  const Dashboard({super.key, required this.user});

  // ── Drawer adapté selon le rôle (Admin vs Étudiant) ───────────────────────
  Widget _drawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Header ISET Nabeul ───────────────────────────────────────────
          DrawerHeader(
            decoration: BoxDecoration(
              color: user.isAdmin ? const Color(0xFF8E24AA) : Colors.teal.shade700,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        user.isAdmin ? Icons.admin_panel_settings : Icons.school,
                        color: user.isAdmin ? const Color(0xFF8E24AA) : Colors.teal.shade700,
                        size: 34,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ISET Nabeul',
                            style: GoogleFonts.oswald(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.isAdmin ? 'Role: ADMINISTRATEUR' : 'Role: ÉTUDIANT',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Exercise for groups : DSI33 and DSI31',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

          // ── MENUS ADMINISTRATEUR (Gère les étudiants et les absences) ────
          if (user.isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.people_alt, color: Colors.blue),
              title: const Text(
                'Manage students',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Ajouter, modifier, supprimer', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EtudiantScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.event_busy, color: Colors.purple),
              title: const Text(
                'Manage absences',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Saisie & gestion de tous les étudiants', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AbsenceScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.how_to_reg, color: Colors.orange),
              title: const Text(
                'Absences par classe',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Saisie collective : classe + matière + date', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SaisieClasseScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment, color: Colors.indigo),
              title: const Text(
                'Relevés de notes',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Consulter et saisir les notes', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReleveNotesScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events, color: Color(0xFFD97706)),
              title: const Text(
                'Classe Max Étudiants',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text('Comptage table Etudiant & MAJ NbrEtud', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ClasseMaxEtudiantsScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work, color: Colors.teal),
              title: const Text(
                'Manage groups',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Classes gérées dans le menu Étudiants')),
                );
              },
            ),
          ],

          // ── MENU ÉTUDIANT (Ne gère pas, voit uniquement ses absences) ────
          if (user.isStudent) ...[
            ListTile(
              leading: const Icon(Icons.school, color: Colors.indigo),
              title: const Text(
                'Consulter mes notes',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Relevé de notes et moyenne générale', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReleveNotesScreen(currentUser: user),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.fact_check, color: Colors.teal),
              title: const Text(
                'Consulter mes absences',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: const Text('Voir mes absences, totaux et graphique', style: TextStyle(fontSize: 11)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MesAbsencesScreen(user: user),
                  ),
                );
              },
            ),
          ],

          const Divider(),

          // ── Close / Logout ───────────────────────────────────────────────
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.red),
            title: const Text(
              'Déconnexion',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
                (_) => false,
              );
            },
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
        title: Text(
          user.isAdmin ? 'Dashboard (Admin)' : 'Dashboard (Étudiant)',
          style: GoogleFonts.oswald(),
        ),
        backgroundColor: user.isAdmin ? const Color(0xFF8E24AA) : Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      drawer: _drawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: user.isAdmin
                ? const [Color(0xFFE8A5DC), Color(0xFFA5B4E8)]
                : const [Color(0xFFB2DFDB), Color(0xFF80CBC4)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Titre "Dashboard" ────────────────────────────────────
                  Text(
                    'Dashboard',
                    style: GoogleFonts.pacifico(
                      fontSize: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Avatar ───────────────────────────────────────────────
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white30,
                    child: Text(
                      user.email.isNotEmpty ? user.email[0].toUpperCase() : '?',
                      style: GoogleFonts.oswald(
                        fontSize: 46,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Badge de rôle clair ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.isAdmin ? 'ESPACE ADMINISTRATEUR' : 'ESPACE ÉTUDIANT',
                      style: TextStyle(
                        color: user.isAdmin ? Colors.purple.shade800 : Colors.teal.shade900,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── BOUTONS ADMINISTRATEUR ───────────────────────────────
                  if (user.isAdmin) ...[
                    _menuButton(
                      context,
                      icon: Icons.people,
                      label: 'Manage Students',
                      color: Colors.blue.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EtudiantScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      context,
                      icon: Icons.event_busy,
                      label: 'Manage Absences',
                      color: Colors.purple.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AbsenceScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      context,
                      icon: Icons.assignment,
                      label: 'Relevés de notes',
                      color: Colors.indigo.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReleveNotesScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      context,
                      icon: Icons.how_to_reg,
                      label: 'Absences par classe',
                      color: Colors.orange.shade700,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SaisieClasseScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      context,
                      icon: Icons.emoji_events,
                      label: 'Classe Max Étudiants',
                      color: const Color(0xFFB45309),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClasseMaxEtudiantsScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── BOUTONS ÉTUDIANT (Consulte notes & absences) ───
                  if (user.isStudent) ...[
                    _menuButton(
                      context,
                      icon: Icons.school,
                      label: 'Consulter mes notes',
                      color: Colors.indigo.shade800,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ReleveNotesScreen(currentUser: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _menuButton(
                      context,
                      icon: Icons.fact_check,
                      label: 'Consulter mes absences',
                      color: Colors.teal.shade800,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MesAbsencesScreen(user: user),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Bouton Déconnexion ───────────────────────────────────
                  _menuButton(
                    context,
                    icon: Icons.logout,
                    label: 'Déconnexion',
                    color: Colors.redAccent,
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const Login()),
                      (_) => false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        minimumSize: const Size(260, 52),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
    );
  }
}

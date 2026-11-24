class User {
  final int id;
  final String email;
  final String role;

  User(this.id, this.email, {this.role = 'ETUDIANT'});

  /// Vérifie si l'utilisateur est un Administrateur
  bool get isAdmin =>
      role.toUpperCase() == 'ADMIN' ||
      email.toLowerCase().trim() == 'admin@gmail.com' ||
      email.toLowerCase().trim().startsWith('admin');

  /// Vérifie si l'utilisateur est un Étudiant
  bool get isStudent => !isAdmin;

  factory User.fromMap(Map<String, dynamic> map) {
    final email = map['email']?.toString() ?? '';
    final role = map['role']?.toString() ??
        (email.toLowerCase().trim() == 'admin@gmail.com' ||
                email.toLowerCase().trim().startsWith('admin')
            ? 'ADMIN'
            : 'ETUDIANT');

    return User(
      (map['id'] as num?)?.toInt() ?? 0,
      email,
      role: role,
    );
  }
}

class Etudiant {
  final String nce;
  final String nom;
  final String prenom;
  final String? dateNais;
  final String? lieuNais;
  final String codClass;

  Etudiant({
    required this.nce,
    required this.nom,
    required this.prenom,
    this.dateNais,
    this.lieuNais,
    required this.codClass,
  });

  factory Etudiant.fromMap(Map<String, dynamic> map) {
    // Récupérer le code de la classe
    String cClass = '';
    if (map['classe'] is Map) {
      // Si la classe est un objet imbriqué, utiliser codClass ou id
      cClass = map['classe']['codClass']?.toString() ??
               map['classe']['id']?.toString() ?? '';
    } else if (map['codClass'] != null) {
      cClass = map['codClass'].toString();
    }

    // NCE : champ nce en priorité, sinon id (pour la rétrocompatibilité)
    String nce = '';
    if (map['nce'] != null && map['nce'].toString().isNotEmpty) {
      nce = map['nce'].toString();
    } else if (map['id'] != null) {
      nce = map['id'].toString();
    }

    return Etudiant(
      nce: nce,
      nom: map['nom']?.toString() ?? '',
      prenom: map['prenom']?.toString() ?? '',
      dateNais: map['dateNais']?.toString(),
      lieuNais: map['lieuNais']?.toString(),
      codClass: cClass,
    );
  }

  String get fullName => '$nom $prenom';

  @override
  bool operator ==(Object other) => other is Etudiant && other.nce == nce;

  @override
  int get hashCode => nce.hashCode;

  @override
  String toString() => '$nce - $nom $prenom';
}

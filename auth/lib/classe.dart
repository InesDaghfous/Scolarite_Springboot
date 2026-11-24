class Classe {
  final int? id;
  final String codClass;
  final String nomClass;
  final int nbrEtud;
  final String codDept;

  Classe({
    this.id,
    required this.codClass,
    required this.nomClass,
    required this.nbrEtud,
    required this.codDept,
  });

  factory Classe.fromMap(Map<String, dynamic> map) {
    // Gestion du code département soit sous forme d'objet soit sous forme de String/id
    String dept = '';
    if (map['departement'] is Map) {
      dept = map['departement']['codDept']?.toString() ??
             map['departement']['id']?.toString() ?? '';
    } else if (map['codDept'] != null) {
      dept = map['codDept'].toString();
    }

    // codClass : champ String en priorité, sinon id numérique
    String cClass = '';
    if (map['codClass'] != null && map['codClass'].toString().isNotEmpty) {
      cClass = map['codClass'].toString();
    } else if (map['id'] != null) {
      cClass = map['id'].toString();
    }

    int? numId;
    if (map['id'] is num) {
      numId = (map['id'] as num).toInt();
    } else if (map['id'] != null) {
      numId = int.tryParse(map['id'].toString());
    }

    return Classe(
      id: numId,
      codClass: cClass,
      nomClass: map['nomClass']?.toString() ?? '',
      nbrEtud: ((map['nbreEtud'] ?? map['nbrEtud']) as num?)?.toInt() ?? 0,
      codDept: dept,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'codClass': codClass,
        'nomClass': nomClass,
        'nbreEtud': nbrEtud,
        if (codDept.isNotEmpty) 'codDept': codDept,
      };

  Classe copyWith({
    int? id,
    String? codClass,
    String? nomClass,
    int? nbrEtud,
    String? codDept,
  }) =>
      Classe(
        id: id ?? this.id,
        codClass: codClass ?? this.codClass,
        nomClass: nomClass ?? this.nomClass,
        nbrEtud: nbrEtud ?? this.nbrEtud,
        codDept: codDept ?? this.codDept,
      );

  @override
  bool operator ==(Object other) =>
      other is Classe && other.codClass == codClass;

  @override
  int get hashCode => codClass.hashCode;

  @override
  String toString() => '$codClass - $nomClass';
}

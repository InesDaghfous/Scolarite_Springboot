class Departement {
  final String codDept;
  final String nomDept;

  Departement({required this.codDept, required this.nomDept});

  factory Departement.fromMap(Map<String, dynamic> map) => Departement(
        // codDept : champ String en priorité, sinon id numérique
        codDept: map['codDept']?.toString().isNotEmpty == true
            ? map['codDept'].toString()
            : map['id']?.toString() ?? '',
        nomDept: map['nomDept']?.toString() ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is Departement && other.codDept == codDept;

  @override
  int get hashCode => codDept.hashCode;

  @override
  String toString() => nomDept;
}

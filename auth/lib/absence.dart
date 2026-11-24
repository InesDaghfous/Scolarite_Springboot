class Absence {
  final int? id;
  final String codMat;
  final String nce;
  final String dateA;
  final double nha;

  Absence({
    this.id,
    required this.codMat,
    required this.nce,
    required this.dateA,
    required this.nha,
  });

  factory Absence.fromMap(Map<String, dynamic> map) {
    String mat = '';
    if (map['matiere'] is Map) {
      mat = map['matiere']['codMat']?.toString() ?? '';
    } else if (map['codMat'] != null) {
      mat = map['codMat'].toString();
    }

    String studentNce = '';
    if (map['etudiant'] is Map) {
      studentNce = (map['etudiant']['nce'] ?? map['etudiant']['id'])?.toString() ?? '';
    } else if (map['nce'] != null) {
      studentNce = map['nce'].toString();
    }

    return Absence(
      id: (map['id'] as num?)?.toInt(),
      codMat: mat,
      nce: studentNce,
      dateA: map['dateA']?.toString() ?? '',
      nha: (map['nha'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'codMat': codMat,
        'nce': nce,
        'dateA': dateA,
        'nha': nha,
      };

  Absence copyWith({
    int? id,
    String? codMat,
    String? nce,
    String? dateA,
    double? nha,
  }) =>
      Absence(
        id: id ?? this.id,
        codMat: codMat ?? this.codMat,
        nce: nce ?? this.nce,
        dateA: dateA ?? this.dateA,
        nha: nha ?? this.nha,
      );
}

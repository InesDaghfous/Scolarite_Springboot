class Note {
  final int? id;
  final String nce;
  final String codMat;
  final String nomMat;
  final double coef;
  final double? tp1;
  final double? tp2;
  final double? ds;
  final double? examen;

  Note({
    this.id,
    required this.nce,
    required this.codMat,
    this.nomMat = '',
    this.coef = 1.0,
    this.tp1,
    this.tp2,
    this.ds,
    this.examen,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: (map['id'] as num?)?.toInt(),
      nce: map['nce']?.toString() ?? '',
      codMat: map['codMat']?.toString() ?? '',
      nomMat: map['nomMat']?.toString() ?? '',
      coef: (map['coef'] as num?)?.toDouble() ?? 1.0,
      tp1: (map['tp1'] as num?)?.toDouble(),
      tp2: (map['tp2'] as num?)?.toDouble(),
      ds: (map['ds'] as num?)?.toDouble(),
      examen: (map['examen'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'nce': nce,
        'codMat': codMat,
        'nomMat': nomMat,
        'coef': coef,
        'tp1': tp1,
        'tp2': tp2,
        'ds': ds,
        'examen': examen,
      };

  /// Moyenne des TPs (50% TP1 + 50% TP2)
  /// Si un seul TP est présent, prend ce TP à 100%.
  double? get moyenneTP {
    if (tp1 != null && tp2 != null) {
      return (tp1! + tp2!) / 2.0;
    } else if (tp1 != null) {
      return tp1!;
    } else if (tp2 != null) {
      return tp2!;
    }
    return null;
  }

  /// Moyenne de l'examen et DS (40% DS + 60% Examen)
  /// Si un seul est présent, prend celui qui est présent.
  double? get moyenneExam {
    if (ds != null && examen != null) {
      return (ds! * 0.40) + (examen! * 0.60);
    } else if (examen != null) {
      return examen!;
    } else if (ds != null) {
      return ds!;
    }
    return null;
  }

  /// Moyenne finale de la matière
  /// - Si la matière n'a que des TPs : moyenne des TPs
  /// - Si la matière n'a que DS/Exam : 40% DS + 60% Exam
  /// - Si la matière a TP ET DS/Exam : 30% TP + 70% (DS/Exam)
  double get moyenneMatiere {
    final tp = moyenneTP;
    final ex = moyenneExam;

    if (tp != null && ex != null) {
      // Épreuve mixte : 30% TPs + 70% Théorie (DS 40% / Exam 60%)
      return (tp * 0.30) + (ex * 0.70);
    } else if (tp != null) {
      return tp;
    } else if (ex != null) {
      return ex;
    }
    return 0.0;
  }

  Note copyWith({
    int? id,
    String? nce,
    String? codMat,
    String? nomMat,
    double? coef,
    double? tp1,
    double? tp2,
    double? ds,
    double? examen,
  }) {
    return Note(
      id: id ?? this.id,
      nce: nce ?? this.nce,
      codMat: codMat ?? this.codMat,
      nomMat: nomMat ?? this.nomMat,
      coef: coef ?? this.coef,
      tp1: tp1 ?? this.tp1,
      tp2: tp2 ?? this.tp2,
      ds: ds ?? this.ds,
      examen: examen ?? this.examen,
    );
  }
}

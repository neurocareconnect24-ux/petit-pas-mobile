enum Language { fr, fon, yoruba }

/// Sexe biologique de l'enfant — requis pour les courbes de croissance OMS
/// (les références L/M/S sont sexe-spécifiques).
enum Sex { male, female }

extension SexExtension on Sex {
  String get code => this == Sex.male ? 'male' : 'female';

  String displayName(Language lang) {
    switch (lang) {
      case Language.fon:
        return this == Sex.male ? 'Sunnu' : 'Nyɔnu';
      case Language.yoruba:
        return this == Sex.male ? 'Ọkùnrin' : 'Obìnrin';
      case Language.fr:
        return this == Sex.male ? 'Garçon' : 'Fille';
    }
  }

  static Sex fromString(String? s) =>
      (s?.toLowerCase() == 'female') ? Sex.female : Sex.male;
}

extension LanguageExtension on Language {
  String get code {
    switch (this) {
      case Language.fr:
        return 'fr';
      case Language.fon:
        return 'fon';
      case Language.yoruba:
        return 'yoruba';
    }
  }

  String get displayName {
    switch (this) {
      case Language.fr:
        return 'Français';
      case Language.fon:
        return 'Fon (Fɔ̀ngbe)';
      case Language.yoruba:
        return 'Yorùbá';
    }
  }

  static Language fromString(String langStr) {
    switch (langStr.toLowerCase()) {
      case 'fon':
        return Language.fon;
      case 'yoruba':
        return Language.yoruba;
      default:
        return Language.fr;
    }
  }
}

class Child {
  final String id;
  final String name;
  final DateTime birthDate;
  final Sex sex;
  final bool isPremature;
  final int? gestationalWeeks;
  final Language language;
  final DateTime createdAt;

  Child({
    required this.id,
    required this.name,
    required this.birthDate,
    this.sex = Sex.male,
    this.isPremature = false,
    this.gestationalWeeks,
    this.language = Language.fr,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'birthDate': birthDate.toIso8601String().split('T')[0],
        'sex': sex.code,
        'isPremature': isPremature,
        'gestationalWeeks': gestationalWeeks,
        'language': language.code,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      birthDate: DateTime.parse(json['birthDate']),
      sex: SexExtension.fromString(json['sex']),
      isPremature: json['isPremature'] ?? false,
      gestationalWeeks: json['gestationalWeeks'],
      language: LanguageExtension.fromString(json['language'] ?? 'fr'),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class AgeCalculation {
  final int chronologicalMonths;
  final int chronologicalDays;
  final int correctedMonths;
  final int correctedDays;
  final bool isCorrected;
  final String currentAgeBracket;
  final String displayText;

  AgeCalculation({
    required this.chronologicalMonths,
    required this.chronologicalDays,
    required this.correctedMonths,
    required this.correctedDays,
    required this.isCorrected,
    required this.currentAgeBracket,
    required this.displayText,
  });

  /// Tranches d'âge (en mois) alignées sur la checklist et les jalons CDC.
  static const List<int> bracketMonths = [2, 4, 6, 9, 12, 15, 18, 24, 30, 36, 48, 60];

  /// Calcule l'âge chronologique et, le cas échéant, l'âge corrigé
  /// (prématurité), et en déduit la tranche de jalons courante.
  factory AgeCalculation.fromChild(Child child, {DateTime? now}) {
    final today = now ?? DateTime.now();

    // Âge chronologique en mois pleins + jours restants.
    int months = (today.year - child.birthDate.year) * 12 +
        (today.month - child.birthDate.month);
    // Ancre le mois de référence pour compter les jours résiduels.
    DateTime anchor = DateTime(
        child.birthDate.year, child.birthDate.month + months, child.birthDate.day);
    if (anchor.isAfter(today)) {
      months -= 1;
      anchor = DateTime(
          child.birthDate.year, child.birthDate.month + months, child.birthDate.day);
    }
    if (months < 0) months = 0;
    final int days = today.difference(anchor).inDays;

    // Correction prématurité : on retranche (40 - âge gestationnel) semaines,
    // seulement jusqu'à 24 mois (pratique pédiatrique courante).
    final bool doCorrect = child.isPremature &&
        child.gestationalWeeks != null &&
        child.gestationalWeeks! < 40 &&
        months < 24;
    int correctedMonths = months;
    int correctedDays = days;
    if (doCorrect) {
      final int correctionDays = (40 - child.gestationalWeeks!) * 7;
      final DateTime corrected = today.subtract(Duration(days: correctionDays));
      int cm = (corrected.year - child.birthDate.year) * 12 +
          (corrected.month - child.birthDate.month);
      DateTime ca = DateTime(
          child.birthDate.year, child.birthDate.month + cm, child.birthDate.day);
      if (ca.isAfter(corrected)) {
        cm -= 1;
        ca = DateTime(
            child.birthDate.year, child.birthDate.month + cm, child.birthDate.day);
      }
      if (cm < 0) cm = 0;
      correctedMonths = cm;
      correctedDays = corrected.difference(ca).inDays;
    }

    // Tranche de jalons : plus grande tranche <= âge (corrigé) en mois.
    int bracket = bracketMonths.first;
    for (final b in bracketMonths) {
      if (correctedMonths >= b) bracket = b;
    }

    return AgeCalculation(
      chronologicalMonths: months,
      chronologicalDays: days,
      correctedMonths: correctedMonths,
      correctedDays: correctedDays,
      isCorrected: doCorrect,
      currentAgeBracket: '${bracket}m',
      displayText: _formatAge(correctedMonths, doCorrect),
    );
  }

  static String _formatAge(int totalMonths, bool corrected) {
    final int years = totalMonths ~/ 12;
    final int months = totalMonths % 12;
    String base;
    if (years == 0) {
      base = '$months mois';
    } else if (months == 0) {
      base = years == 1 ? '1 an' : '$years ans';
    } else {
      base = '${years == 1 ? '1 an' : '$years ans'} $months mois';
    }
    return corrected ? '$base (âge corrigé)' : base;
  }
}

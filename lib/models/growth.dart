/// Indicateurs anthropométriques suivis (normes OMS 0-5 ans).
enum GrowthIndicator { weightForAge, heightForAge, headCircForAge }

extension GrowthIndicatorExtension on GrowthIndicator {
  String get code {
    switch (this) {
      case GrowthIndicator.weightForAge:
        return 'wfa';
      case GrowthIndicator.heightForAge:
        return 'hfa';
      case GrowthIndicator.headCircForAge:
        return 'hcfa';
    }
  }

  String get label {
    switch (this) {
      case GrowthIndicator.weightForAge:
        return 'Poids-pour-âge';
      case GrowthIndicator.heightForAge:
        return 'Taille-pour-âge';
      case GrowthIndicator.headCircForAge:
        return 'Périmètre crânien-pour-âge';
    }
  }

  String get unit {
    switch (this) {
      case GrowthIndicator.weightForAge:
        return 'kg';
      case GrowthIndicator.heightForAge:
      case GrowthIndicator.headCircForAge:
        return 'cm';
    }
  }
}

/// Une mesure anthropométrique saisie à une date donnée.
/// Les champs sont optionnels : le parent peut ne renseigner qu'une mesure.
class GrowthMeasurement {
  final String id;
  final String childId;
  final DateTime date;
  final double? weightKg;
  final double? heightCm;
  final double? headCircCm;

  GrowthMeasurement({
    required this.id,
    required this.childId,
    required this.date,
    this.weightKg,
    this.heightCm,
    this.headCircCm,
  });

  double? valueFor(GrowthIndicator indicator) {
    switch (indicator) {
      case GrowthIndicator.weightForAge:
        return weightKg;
      case GrowthIndicator.heightForAge:
        return heightCm;
      case GrowthIndicator.headCircForAge:
        return headCircCm;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'heightCm': heightCm,
        'headCircCm': headCircCm,
      };

  factory GrowthMeasurement.fromJson(Map<String, dynamic> json) {
    return GrowthMeasurement(
      id: json['id'] ?? '',
      childId: json['childId'] ?? '',
      date: DateTime.parse(json['date']),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      headCircCm: (json['headCircCm'] as num?)?.toDouble(),
    );
  }
}

/// Classification OMS d'un z-score (par écart-type à la médiane).
enum GrowthStatus { severe, moderate, normal, high, severeHigh }

/// Résultat d'un calcul de z-score pour un indicateur donné.
class ZScoreResult {
  final GrowthIndicator indicator;
  final double value; // la mesure saisie
  final int ageMonths;
  final double zScore;
  final GrowthStatus status;

  ZScoreResult({
    required this.indicator,
    required this.value,
    required this.ageMonths,
    required this.zScore,
    required this.status,
  });

  /// Un statut sévère ou modéré déclenche un signal d'alerte croissance.
  bool get isAlert =>
      status == GrowthStatus.severe ||
      status == GrowthStatus.moderate ||
      status == GrowthStatus.high ||
      status == GrowthStatus.severeHigh;

  bool get isHighSeverity =>
      status == GrowthStatus.severe || status == GrowthStatus.severeHigh;
}

import 'dart:math' as math;
import '../models/child.dart';
import '../models/growth.dart';
import '../data/who_growth_data.dart';

/// Calcule les z-scores de croissance selon la méthode LMS de l'OMS,
/// classe le résultat selon les seuils OMS (±2 / ±3 écarts-types) et
/// en déduit des signaux d'alerte nutritionnels/croissance.
class GrowthService {
  static const int maxAgeMonths = 60;

  /// Interpole les paramètres LMS pour un âge donné (linéaire entre ancres).
  static LMS? _lmsAt(GrowthIndicator indicator, Sex sex, int ageMonths) {
    final table = whoGrowthLms[whoKey(indicator, sex)];
    if (table == null) return null;

    final ages = table.keys.toList()..sort();
    if (ages.isEmpty) return null;

    // Bornage aux extrémités de la table.
    if (ageMonths <= ages.first) return table[ages.first];
    if (ageMonths >= ages.last) return table[ages.last];

    // Recherche de l'intervalle encadrant.
    int lower = ages.first;
    int upper = ages.last;
    for (final a in ages) {
      if (a <= ageMonths) lower = a;
      if (a >= ageMonths) {
        upper = a;
        break;
      }
    }
    if (lower == upper) return table[lower];

    final lo = table[lower]!;
    final hi = table[upper]!;
    final t = (ageMonths - lower) / (upper - lower);
    return LMS(
      lo.l + (hi.l - lo.l) * t,
      lo.m + (hi.m - lo.m) * t,
      lo.s + (hi.s - lo.s) * t,
    );
  }

  /// Z-score OMS : z = ((X/M)^L - 1) / (L·S), ou ln(X/M)/S si L≈0.
  static double? zScore({
    required GrowthIndicator indicator,
    required Sex sex,
    required int ageMonths,
    required double value,
  }) {
    if (value <= 0) return null;
    final lms = _lmsAt(indicator, sex, ageMonths);
    if (lms == null) return null;

    double z;
    if (lms.l.abs() < 1e-7) {
      z = math.log(value / lms.m) / lms.s;
    } else {
      z = (math.pow(value / lms.m, lms.l) - 1) / (lms.l * lms.s);
    }
    return z;
  }

  /// Valeur correspondant à un z-score donné, à un âge donné (inverse LMS).
  /// Sert à tracer les couloirs de référence (médiane, ±2, ±3 SD).
  static double? valueForZ({
    required GrowthIndicator indicator,
    required Sex sex,
    required int ageMonths,
    required double z,
  }) {
    final lms = _lmsAt(indicator, sex, ageMonths);
    if (lms == null) return null;
    if (lms.l.abs() < 1e-7) {
      return lms.m * math.exp(lms.s * z);
    }
    final base = 1 + lms.l * lms.s * z;
    if (base <= 0) return null;
    return lms.m * math.pow(base, 1 / lms.l).toDouble();
  }

  /// Classement OMS d'un z-score selon les seuils standard.
  static GrowthStatus classify(double z) {
    if (z < -3) return GrowthStatus.severe;
    if (z < -2) return GrowthStatus.moderate;
    if (z > 3) return GrowthStatus.severeHigh;
    if (z > 2) return GrowthStatus.high;
    return GrowthStatus.normal;
  }

  /// Évalue un indicateur pour une mesure donnée. Retourne null si l'indicateur
  /// n'est pas renseigné ou hors référentiel.
  static ZScoreResult? evaluate({
    required GrowthIndicator indicator,
    required Child child,
    required int ageMonths,
    required double? value,
  }) {
    if (value == null || value <= 0) return null;
    final z = zScore(
      indicator: indicator,
      sex: child.sex,
      ageMonths: ageMonths,
      value: value,
    );
    if (z == null) return null;
    return ZScoreResult(
      indicator: indicator,
      value: value,
      ageMonths: ageMonths,
      zScore: z,
      status: classify(z),
    );
  }

  /// Libellé clinique du statut, propre à l'indicateur (langue FR).
  static String statusLabel(GrowthIndicator indicator, GrowthStatus status) {
    switch (indicator) {
      case GrowthIndicator.weightForAge:
        switch (status) {
          case GrowthStatus.severe:
            return 'Insuffisance pondérale sévère';
          case GrowthStatus.moderate:
            return 'Insuffisance pondérale';
          case GrowthStatus.high:
          case GrowthStatus.severeHigh:
            return 'Poids élevé pour l’âge';
          case GrowthStatus.normal:
            return 'Poids normal pour l’âge';
        }
      case GrowthIndicator.heightForAge:
        switch (status) {
          case GrowthStatus.severe:
            return 'Retard de croissance sévère';
          case GrowthStatus.moderate:
            return 'Retard de croissance';
          case GrowthStatus.high:
          case GrowthStatus.severeHigh:
            return 'Taille élevée pour l’âge';
          case GrowthStatus.normal:
            return 'Taille normale pour l’âge';
        }
      case GrowthIndicator.headCircForAge:
        switch (status) {
          case GrowthStatus.severe:
            return 'Microcéphalie probable (à confirmer)';
          case GrowthStatus.moderate:
            return 'Périmètre crânien bas';
          case GrowthStatus.high:
            return 'Périmètre crânien élevé';
          case GrowthStatus.severeHigh:
            return 'Macrocéphalie probable (à confirmer)';
          case GrowthStatus.normal:
            return 'Périmètre crânien normal';
        }
    }
  }

  /// Évalue les 3 indicateurs pour la mesure la plus récente d'un enfant.
  static List<ZScoreResult> evaluateMeasurement({
    required Child child,
    required GrowthMeasurement measurement,
  }) {
    final ageMonths = _ageInMonths(child.birthDate, measurement.date);
    final results = <ZScoreResult>[];
    for (final ind in GrowthIndicator.values) {
      final r = evaluate(
        indicator: ind,
        child: child,
        ageMonths: ageMonths,
        value: measurement.valueFor(ind),
      );
      if (r != null) results.add(r);
    }
    return results;
  }

  static int _ageInMonths(DateTime birth, DateTime at) {
    int m = (at.year - birth.year) * 12 + (at.month - birth.month);
    if (at.day < birth.day) m -= 1;
    return m < 0 ? 0 : m;
  }
}

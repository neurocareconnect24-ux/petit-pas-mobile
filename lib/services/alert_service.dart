import '../models/child.dart';
import '../models/milestone.dart';
import '../models/growth.dart';
import '../services/content_service.dart';
import 'growth_service.dart';

/// Gravité d'un signal de vigilance développementale.
enum AlertSeverity { none, moderate, high }

/// Un signal d'alerte concernant un jalon « à surveiller » (red flag CDC)
/// que l'enfant devrait avoir acquis compte tenu de son âge.
class WatchAlert {
  final Milestone milestone;
  final AlertSeverity severity;

  /// Nombre de mois de retard sur la borne du jalon (âge - borneAttendue).
  final int monthsOverdue;

  WatchAlert({
    required this.milestone,
    required this.severity,
    required this.monthsOverdue,
  });

  /// Libellé du jalon dans la langue de l'enfant.
  String label(Language lang) =>
      milestone.text[lang] ?? milestone.text[Language.fr] ?? milestone.id;
}

/// Synthèse des signaux de vigilance pour un enfant à un instant donné.
/// Regroupe les signaux développementaux (jalons) ET de croissance (z-scores).
class WatchAlertReport {
  final List<WatchAlert> alerts; // jalons, triés du plus grave au moins grave
  final List<ZScoreResult> growthAlerts; // croissance (z-score hors normes)
  final AgeCalculation age;

  WatchAlertReport({
    required this.alerts,
    required this.age,
    this.growthAlerts = const [],
  });

  int get highCount =>
      alerts.where((a) => a.severity == AlertSeverity.high).length +
      growthAlerts.where((g) => g.isHighSeverity).length;

  int get moderateCount =>
      alerts.where((a) => a.severity == AlertSeverity.moderate).length +
      growthAlerts.where((g) => g.isAlert && !g.isHighSeverity).length;

  bool get hasAny => alerts.isNotEmpty || growthAlerts.isNotEmpty;

  AlertSeverity get overall {
    if (highCount > 0) return AlertSeverity.high;
    if (moderateCount > 0) return AlertSeverity.moderate;
    return AlertSeverity.none;
  }

  /// Message d'orientation adapté à la gravité, dans la langue de l'enfant.
  String recommendation(Language lang) {
    switch (overall) {
      case AlertSeverity.high:
        return _t(lang, _recoHigh);
      case AlertSeverity.moderate:
        return _t(lang, _recoModerate);
      case AlertSeverity.none:
        return _t(lang, _recoNone);
    }
  }

  String title(Language lang) {
    switch (overall) {
      case AlertSeverity.high:
        return _t(lang, _titleHigh);
      case AlertSeverity.moderate:
        return _t(lang, _titleModerate);
      case AlertSeverity.none:
        return _t(lang, _titleNone);
    }
  }
}

/// Convertit une borne de tranche ('12m') en nombre de mois (12).
int _bracketToMonths(String bracket) =>
    int.tryParse(bracket.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

class AlertService {
  /// Évalue les signaux de vigilance en fonction de l'âge (corrigé si
  /// prématuré), des jalons renseignés et — si fournies — des dernières
  /// mesures de croissance (z-scores OMS hors normes).
  static WatchAlertReport evaluate(
    Child child,
    Map<String, MilestoneRecord> records, {
    DateTime? now,
    List<GrowthMeasurement> measurements = const [],
  }) {
    final age = AgeCalculation.fromChild(child, now: now);
    final int ageMonths = age.correctedMonths;

    final List<WatchAlert> alerts = [];

    for (final m in ContentService.milestones) {
      if (!m.isWatchItem) continue;

      final int due = _bracketToMonths(m.ageBracket);
      // Le signal n'est pertinent que si l'enfant a atteint/dépassé la borne.
      if (ageMonths < due) continue;

      final status = records[m.id]?.status ?? MilestoneStatus.unknown;
      if (status == MilestoneStatus.achieved || status == MilestoneStatus.unknown) continue;

      final AlertSeverity severity = status == MilestoneStatus.notYet
          ? AlertSeverity.high // non acquis alors qu'attendu → orienter
          : AlertSeverity.moderate; // emerging (parfois) → à vérifier

      alerts.add(WatchAlert(
        milestone: m,
        severity: severity,
        monthsOverdue: ageMonths - due,
      ));
    }

    // Tri : gravité décroissante puis retard décroissant.
    alerts.sort((a, b) {
      final s = b.severity.index.compareTo(a.severity.index);
      if (s != 0) return s;
      return b.monthsOverdue.compareTo(a.monthsOverdue);
    });

    // Signaux de croissance : évalués sur la mesure la plus récente.
    final List<ZScoreResult> growthAlerts = [];
    if (measurements.isNotEmpty) {
      final latest = measurements.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
      final results =
          GrowthService.evaluateMeasurement(child: child, measurement: latest);
      for (final r in results) {
        if (r.isAlert) growthAlerts.add(r);
      }
      // Plus grave (sévère) d'abord, puis par écart à la médiane.
      growthAlerts.sort((a, b) {
        final s = (b.isHighSeverity ? 1 : 0).compareTo(a.isHighSeverity ? 1 : 0);
        if (s != 0) return s;
        return b.zScore.abs().compareTo(a.zScore.abs());
      });
    }

    return WatchAlertReport(
      alerts: alerts,
      age: age,
      growthAlerts: growthAlerts,
    );
  }
}

// ── Chaînes multilingues ─────────────────────────────────────────────

String _t(Language lang, Map<Language, String> m) =>
    m[lang] ?? m[Language.fr]!;

const Map<Language, String> _titleHigh = {
  Language.fr: 'Signaux à partager avec un soignant',
  Language.fon: 'Nǔ e ɖé sixu byɔ́ dotóo é',
  Language.yoruba: 'Àwọn àmì láti sọ fún dókítà',
};
const Map<Language, String> _titleModerate = {
  Language.fr: 'Points de vigilance à vérifier',
  Language.fon: 'Nǔ e è ɖó na kpɔ́n é',
  Language.yoruba: 'Àwọn àmì láti yẹ̀wò',
};
const Map<Language, String> _titleNone = {
  Language.fr: 'Aucun signal d’alerte',
  Language.fon: 'Nǔ ɖ’ayǐ ɖé ɖè ǎ',
  Language.yoruba: 'Kò sí àmì ìkìlọ̀',
};

const Map<Language, String> _recoHigh = {
  Language.fr:
      'Un ou plusieurs signaux de vigilance (développement ou croissance) sont hors des repères attendus à cet âge. Ce n’est pas un diagnostic, mais il est recommandé d’en parler à un médecin ou en téléconsultation NeuroCare Connect.',
  Language.fon:
      'Nǔ ɖé lɛ́ (nukɔnyiyi kabǐ agbaza) tɔ́n sín ali e ɖò xwè élɔ́ mɛ é. Nyí azɔn wɛ á, loɔ à ɖó na ɖɔ nú dotóo kabǐ NeuroCare Connect.',
  Language.yoruba:
      'Àwọn àmì kan (ìdàgbàsókè tàbí ìdàgbà ara) kọjá àwọn àmì tó yẹ ní ọjọ́ orí yìí. Kì í ṣe àyẹ̀wò, ṣùgbọ́n ó dára láti bá dókítà sọ̀rọ̀ tàbí NeuroCare Connect.',
};
const Map<Language, String> _recoModerate = {
  Language.fr:
      'Certains repères importants pour cet âge ne sont pas encore renseignés. Complétez leur évaluation pour un suivi fiable.',
  Language.fon:
      'Nǔ taji ɖé lɛ́ nú xwè élɔ́ è ko sɔ́ ɖ’ayǐ ǎ. Bló nǔ lɛ́ bɔ è na kpɔ́n ganji.',
  Language.yoruba:
      'Àwọn àmì pàtàkì kan fún ọjọ́ orí yìí kò tíì wà. Parí àyẹ̀wò wọn fún ìtọ́jú tó dájú.',
};
const Map<Language, String> _recoNone = {
  Language.fr:
      'Aucun signal de vigilance à ce stade. Continuez le suivi régulier des jalons.',
  Language.fon: 'Nǔ ɖ’ayǐ ɖé ɖè ǎ. Kpó ɖò nukɔnyiyi lɛ́ kpɔ́n wɛ.',
  Language.yoruba:
      'Kò sí àmì ìkìlọ̀ nísinsìnyí. Máa bá àyẹ̀wò àwọn àmì lọ.',
};

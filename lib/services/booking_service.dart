import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import 'alert_service.dart';

/// Assure la passerelle entre Petit Pas et l'application de
/// téléconsultation Petit Pas Meet.
///
/// Stratégie de redirection (du plus direct au repli) :
///   1. Deep link natif `petitpasmeet://rdv?...` → ouvre l'app Petit Pas Meet si installée.
///   2. Repli Universal Link / web `https://…/rdv?...` → page de RDV
///      (qui peut elle-même rediriger vers le store si besoin).
///
/// Le contexte de l'enfant (prénom, âge, langue, signaux d'alerte) est passé
/// en paramètres pour pré-remplir le motif de consultation côté téléconsultation.
class BookingService {
  // ── À adapter à ton infrastructure ──────────────────────────
  /// Schéma custom déclaré par l'app Petit Pas Meet (Android intent-filter / iOS scheme).
  static const String appScheme = 'petitpasmeet';
  static const String appDeepLinkHost = 'rdv';

  /// URL web de prise de RDV.
  static String webBookingUrl = 'https://meet.bonkano.fr/rdv/teleconsultation-neurocare-connect';
  // ─────────────────────────────────────────────────────────────────────

  /// Résultat de la tentative d'ouverture, pour informer l'UI.
  static Future<BookingLaunchResult> openBooking({
    required Child child,
    required Map<String, MilestoneRecord> records,
  }) async {
    final contextParams = _buildContextParams(child, records);
    // On ajoute le service_id demandé par défaut
    final params = {'service_id': '68', ...contextParams};

    // Ouverture directe en Webview interne
    final webUri = Uri.parse(webBookingUrl).replace(queryParameters: params);
    try {
      final opened = await launchUrl(webUri, mode: LaunchMode.inAppWebView);
      if (opened) return BookingLaunchResult.webOpened;
    } catch (e) {
      if (kDebugMode) print('Échec ouverture web : $e');
    }

    return BookingLaunchResult.failed;
  }

  /// Construit les paramètres de contexte transmis à Bonkano.
  static Map<String, String> _buildContextParams(
    Child child,
    Map<String, MilestoneRecord> records,
  ) {
    final age = AgeCalculation.fromChild(child);
    final report = AlertService.evaluate(child, records);

    // Signaux d'alerte : ids des jalons rouges (à orienter) et ambres (à vérifier).
    final highIds = report.alerts
        .where((a) => a.severity == AlertSeverity.high)
        .map((a) => a.milestone.id)
        .join(',');
    final moderateIds = report.alerts
        .where((a) => a.severity == AlertSeverity.moderate)
        .map((a) => a.milestone.id)
        .join(',');

    return {
      'source': 'neurocare_track',
      'reason': 'developmental_surveillance',
      'childName': child.name,
      'childId': child.id,
      'ageMonths': age.correctedMonths.toString(),
      'ageText': age.displayText,
      'isPremature': child.isPremature.toString(),
      'language': child.language.code,
      'flagsHigh': highIds,
      'flagsModerate': moderateIds,
      'flagCount': report.alerts.length.toString(),
    };
  }
}

enum BookingLaunchResult { appOpened, webOpened, failed }

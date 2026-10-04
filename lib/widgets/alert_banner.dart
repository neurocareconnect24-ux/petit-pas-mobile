import 'package:flutter/material.dart';
import '../models/child.dart';
import '../services/alert_service.dart';
import '../services/growth_service.dart';

/// Bannière de vigilance affichée en tête d'écran lorsqu'un ou plusieurs
/// signaux « à surveiller » ne sont pas acquis pour l'âge de l'enfant.
///
/// Ne s'affiche pas quand il n'y a aucun signal (rien à alarmer inutilement).
class AlertBanner extends StatelessWidget {
  final WatchAlertReport report;
  final Language language;

  /// Appelé quand le parent tape « Voir / Orienter » (ex : aller à l'onglet RDV).
  final VoidCallback? onOpenConsultation;

  const AlertBanner({
    super.key,
    required this.report,
    required this.language,
    this.onOpenConsultation,
  });

  @override
  Widget build(BuildContext context) {
    if (!report.hasAny) return const SizedBox.shrink();

    final bool high = report.overall == AlertSeverity.high;
    final Color base = high ? const Color(0xFFD32F2F) : const Color(0xFFF9A825);
    final Color bg = high ? const Color(0xFFFDECEA) : const Color(0xFFFFF8E1);
    final IconData icon =
        high ? Icons.report_gmailerrorred : Icons.info_outline;

    // Les 3 signaux les plus graves, pour ne pas noyer le parent.
    final preview = report.alerts.take(3).toList();
    final int extra = report.alerts.length - preview.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: base.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: base, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  report.title(language),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: base,
                  ),
                ),
              ),
              if (report.highCount > 0)
                _Pill(text: '${report.highCount}', color: const Color(0xFFD32F2F)),
              if (report.moderateCount > 0) ...[
                const SizedBox(width: 6),
                _Pill(text: '${report.moderateCount}', color: const Color(0xFFF9A825)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.recommendation(language),
            style: const TextStyle(fontSize: 12, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 10),
          ...preview.map(
            (a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    a.severity == AlertSeverity.high
                        ? Icons.error_outline
                        : Icons.help_outline,
                    size: 15,
                    color: a.severity == AlertSeverity.high
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFFF9A825),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      a.label(language),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Signaux de croissance (z-scores hors normes OMS).
          ...report.growthAlerts.map(
            (g) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    g.isHighSeverity ? Icons.error_outline : Icons.monitor_weight_outlined,
                    size: 15,
                    color: g.isHighSeverity
                        ? const Color(0xFFD32F2F)
                        : const Color(0xFFF9A825),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${GrowthService.statusLabel(g.indicator, g.status)} (z=${g.zScore.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF333333)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (extra > 0)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '+ $extra autre(s)',
                style: const TextStyle(
                    fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
          if (high && onOpenConsultation != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: base,
                  side: BorderSide(color: base),
                ),
                icon: const Icon(Icons.medical_services_outlined, size: 18),
                label: const Text('En parler à un soignant'),
                onPressed: onOpenConsultation,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}

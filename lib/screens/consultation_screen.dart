import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../services/content_service.dart';
import '../services/alert_service.dart';

class ConsultationScreen extends StatefulWidget {
  final Child activeChild;
  final Map<String, MilestoneRecord> records;

  const ConsultationScreen({
    super.key,
    required this.activeChild,
    required this.records,
  });

  @override
  State<ConsultationScreen> createState() => _ConsultationScreenState();
}

class _ConsultationScreenState extends State<ConsultationScreen> {
  bool _showWebView = false;
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();
    // Configure le contrôleur pour afficher le RDV dans l'application
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));
  }

  /// Construit le texte du bilan à partager avec le soignant.
  String _buildReport() {
    final age = AgeCalculation.fromChild(widget.activeChild);
    final lang = widget.activeChild.language;

    final byId = {for (final m in ContentService.milestones) m.id: m};
    final validRecords = widget.records.values.where((r) => byId.containsKey(r.milestoneId)).toList();

    String labelFor(String id) {
      final m = byId[id]!;
      return m.text[lang] ?? m.text[Language.fr] ?? id;
    }

    final achieved = validRecords
        .where((r) => r.status == MilestoneStatus.achieved)
        .map((r) => '  ✔ ${labelFor(r.milestoneId)}')
        .toList();
    final pending = validRecords
        .where((r) => isToFollow(r.status))
        .map((r) => '  ⏳ ${labelFor(r.milestoneId)}${r.status == MilestoneStatus.emerging ? ' (parfois)' : ''}')
        .toList();

    final b = StringBuffer()
      ..writeln('BILAN DE SURVEILLANCE DÉVELOPPEMENTALE — NeuroCare Connect')
      ..writeln('Édité par NeuroCare Group')
      ..writeln('')
      ..writeln('Enfant : ${widget.activeChild.name}')
      ..writeln(
          'Date de naissance : ${widget.activeChild.birthDate.day}/${widget.activeChild.birthDate.month}/${widget.activeChild.birthDate.year}')
      ..writeln('Âge : ${age.displayText}')
      ..writeln(
          'Prématurité : ${widget.activeChild.isPremature ? "Oui (${widget.activeChild.gestationalWeeks} semaines)" : "Non"}')
      ..writeln('Tranche de jalons courante : ${age.currentAgeBracket}')
      ..writeln('')
      ..writeln('Jalons acquis (${achieved.length}) :')
      ..writeln(achieved.isEmpty ? '  (aucun renseigné)' : achieved.join('\n'))
      ..writeln('')
      ..writeln('Jalons en attente (${pending.length}) :')
      ..writeln(pending.isEmpty ? '  (aucun renseigné)' : pending.join('\n'))
      ..writeln('');

    final report = AlertService.evaluate(widget.activeChild, widget.records);
    b.writeln('⚠ Signaux de vigilance (${report.alerts.length}) :');
    if (report.alerts.isEmpty) {
      b.writeln('  (aucun à ce stade)');
    } else {
      for (final a in report.alerts) {
        final tag = a.severity == AlertSeverity.high ? '[À ORIENTER]' : '[À VÉRIFIER]';
        b.writeln('  $tag ${a.label(lang)}');
      }
    }
    b
      ..writeln('')
      ..writeln(
          'Document indicatif généré par les parents — ne constitue pas un diagnostic médical.');
    return b.toString();
  }

  void _openBookingInApp() {
    // Crée l'URL final avec le bon ID
    final webUri = Uri.parse('https://meet.bonkano.fr/rdv/teleconsultation-neurocare-connect').replace(
      queryParameters: {'service_id': '68'},
    );
    _webController.loadRequest(webUri);
    setState(() {
      _showWebView = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showWebView) {
      return Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _showWebView = false),
                ),
                const Text('Prendre rendez-vous', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: WebViewWidget(controller: _webController),
          ),
        ],
      );
    }

    final achievedCount = widget.records.values.where((r) => r.status == MilestoneStatus.achieved).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description, color: Color(0xFF4693D4)),
                      SizedBox(width: 8),
                      Text(
                        'Synthèse de consultation pédiatrique',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Text('Enfant : ${widget.activeChild.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Date de naissance : ${widget.activeChild.birthDate.day}/${widget.activeChild.birthDate.month}/${widget.activeChild.birthDate.year}'),
                  Text('Âge : ${AgeCalculation.fromChild(widget.activeChild).displayText}'),
                  Text('Prématurité : ${widget.activeChild.isPremature ? "Oui (${widget.activeChild.gestationalWeeks} semaines)" : "Non"}'),
                  const SizedBox(height: 12),
                  Text('Jalons observés acquis : $achievedCount'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4693D4),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    icon: const Icon(Icons.share),
                    label: const Text('Partager le bilan à votre médecin'),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _buildReport()));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bilan copié dans le presse-papier pour envoi.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Téléconsultation NCC
          Card(
            color: Colors.teal.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.video_call, color: Colors.teal, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Prendre RDV en téléconsultation',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Besoin d’un avis médical spécialisé ? Prenez rendez-vous directement avec un soignant sur NeuroCare Connect.',
                    style: TextStyle(fontSize: 12, color: Colors.teal),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    onPressed: _openBookingInApp,
                    label: const Text('Prendre rendez-vous'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

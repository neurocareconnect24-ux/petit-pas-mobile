import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/growth.dart';
import '../services/growth_service.dart';
import '../services/storage_service.dart';

/// Écran de suivi de la croissance : saisie des mesures, courbe OMS
/// (médiane + couloirs ±2/±3 SD) et interprétation des z-scores.
class GrowthScreen extends StatefulWidget {
  final Child activeChild;

  /// Notifie le parent (HomeScreen) pour rafraîchir la bannière d'alerte.
  final void Function(List<GrowthMeasurement>)? onMeasurementsChanged;

  const GrowthScreen({
    super.key,
    required this.activeChild,
    this.onMeasurementsChanged,
  });

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  List<GrowthMeasurement> _measurements = [];
  GrowthIndicator _indicator = GrowthIndicator.weightForAge;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await StorageService.getMeasurements(widget.activeChild.id);
    if (!mounted) return;
    setState(() {
      _measurements = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF4693D4)));
    }

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            // Sélecteur d'indicateur
            SegmentedButton<GrowthIndicator>(
              segments: const [
                ButtonSegment(value: GrowthIndicator.weightForAge, label: Text('Poids'), icon: Icon(Icons.monitor_weight_outlined, size: 18)),
                ButtonSegment(value: GrowthIndicator.heightForAge, label: Text('Taille'), icon: Icon(Icons.height, size: 18)),
                ButtonSegment(value: GrowthIndicator.headCircForAge, label: Text('PC'), icon: Icon(Icons.face_outlined, size: 18)),
              ],
              selected: {_indicator},
              onSelectionChanged: (s) => setState(() => _indicator = s.first),
            ),
            const SizedBox(height: 16),

            // Courbe OMS
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_indicator.label} — ${widget.activeChild.sex.displayName(widget.activeChild.language)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    AspectRatio(
                      aspectRatio: 1.4,
                      child: CustomPaint(
                        painter: _GrowthChartPainter(
                          child: widget.activeChild,
                          indicator: _indicator,
                          measurements: _measurements,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const _Legend(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Interprétation de la dernière mesure
            if (_measurements.isNotEmpty) _latestInterpretation(),

            const SizedBox(height: 8),
            Text('Historique des mesures',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            if (_measurements.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('Aucune mesure enregistrée.', style: TextStyle(color: Colors.grey))),
              )
            else
              ..._measurements.reversed.map(_measurementTile),

            const SizedBox(height: 12),
            // Avertissement données provisoires
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Références officielles OMS 2006 (0-5 ans), paramètres L/M/S par mois et par sexe. Outil d’information : ceci n’est pas un diagnostic médical.',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),

        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF4693D4),
            icon: const Icon(Icons.add),
            label: const Text('Mesure'),
            onPressed: _openAddDialog,
          ),
        ),
      ],
    );
  }

  Widget _latestInterpretation() {
    final last = _measurements.last;
    final results = GrowthService.evaluateMeasurement(child: widget.activeChild, measurement: last);
    if (results.isEmpty) return const SizedBox.shrink();

    return Card(
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dernière évaluation (${_fmtDate(last.date)})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...results.map((r) {
              final color = _statusColor(r);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(r.isAlert ? Icons.warning_amber_rounded : Icons.check_circle,
                        size: 16, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${r.indicator.label} : ${GrowthService.statusLabel(r.indicator, r.status)}',
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text('z=${r.zScore.toStringAsFixed(1)}',
                        style: TextStyle(fontSize: 11, color: color)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _measurementTile(GrowthMeasurement m) {
    final parts = <String>[];
    if (m.weightKg != null) parts.add('${m.weightKg} kg');
    if (m.heightCm != null) parts.add('${m.heightCm} cm');
    if (m.headCircCm != null) parts.add('PC ${m.headCircCm} cm');
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        dense: true,
        leading: const Icon(Icons.event_note, color: Color(0xFF4693D4)),
        title: Text(parts.join('  •  '), style: const TextStyle(fontSize: 13)),
        subtitle: Text(_fmtDate(m.date), style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
          onPressed: () async {
            final list = await StorageService.deleteMeasurement(widget.activeChild.id, m.id);
            if (mounted) setState(() => _measurements = list);
            widget.onMeasurementsChanged?.call(list);
          },
        ),
      ),
    );
  }

  Color _statusColor(ZScoreResult r) {
    if (r.isHighSeverity) return const Color(0xFFD32F2F);
    if (r.isAlert) return const Color(0xFFF9A825);
    return Colors.green.shade700;
  }

  Future<void> _openAddDialog() async {
    final wCtrl = TextEditingController();
    final hCtrl = TextEditingController();
    final pcCtrl = TextEditingController();
    DateTime date = DateTime.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Nouvelle mesure'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Date : ${_fmtDate(date)}')),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          initialDate: date,
                          firstDate: widget.activeChild.birthDate,
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setD(() => date = picked);
                      },
                      child: const Text('Changer'),
                    ),
                  ],
                ),
                _numField(wCtrl, 'Poids (kg)'),
                _numField(hCtrl, 'Taille (cm)'),
                _numField(pcCtrl, 'Périmètre crânien (cm)'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4693D4), foregroundColor: Colors.white),
              onPressed: () async {
                final w = double.tryParse(wCtrl.text.replaceAll(',', '.'));
                final h = double.tryParse(hCtrl.text.replaceAll(',', '.'));
                final pc = double.tryParse(pcCtrl.text.replaceAll(',', '.'));
                if (w == null && h == null && pc == null) {
                  Navigator.pop(ctx);
                  return;
                }
                final measurement = GrowthMeasurement(
                  id: 'g_${DateTime.now().millisecondsSinceEpoch}',
                  childId: widget.activeChild.id,
                  date: date,
                  weightKg: w,
                  heightCm: h,
                  headCircCm: pc,
                );
                final list = await StorageService.saveMeasurement(measurement);
                if (mounted) setState(() => _measurements = list);
                widget.onMeasurementsChanged?.call(list);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numField(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder()),
        ),
      );

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String t) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 14, height: 3, color: c),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(fontSize: 9, color: Colors.grey)),
        ]);
    return Wrap(spacing: 12, runSpacing: 4, children: [
      item(Colors.green, 'Médiane'),
      item(Colors.orange, '±2 SD'),
      item(Colors.red, '±3 SD'),
      Row(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.circle, size: 8, color: Color(0xFF4693D4)),
        SizedBox(width: 4),
        Text('Enfant', style: TextStyle(fontSize: 9, color: Colors.grey)),
      ]),
    ]);
  }
}

/// Trace les couloirs OMS (médiane, ±2, ±3 SD) et les points de l'enfant.
class _GrowthChartPainter extends CustomPainter {
  final Child child;
  final GrowthIndicator indicator;
  final List<GrowthMeasurement> measurements;

  _GrowthChartPainter({
    required this.child,
    required this.indicator,
    required this.measurements,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const int maxMonths = 60;

    // Détermine l'échelle Y à partir des couloirs ±3 SD sur tout l'intervalle.
    double minY = double.infinity, maxY = -double.infinity;
    for (int m = 0; m <= maxMonths; m++) {
      for (final z in [-3.0, 3.0]) {
        final v = GrowthService.valueForZ(indicator: indicator, sex: child.sex, ageMonths: m, z: z);
        if (v != null) {
          minY = v < minY ? v : minY;
          maxY = v > maxY ? v : maxY;
        }
      }
    }
    if (minY == double.infinity) return;
    // Inclut les points de l'enfant dans l'échelle.
    for (final meas in measurements) {
      final v = meas.valueFor(indicator);
      if (v != null) {
        minY = v < minY ? v : minY;
        maxY = v > maxY ? v : maxY;
      }
    }
    final pad = (maxY - minY) * 0.08 + 0.5;
    minY -= pad;
    maxY += pad;

    double dx(int months) => size.width * (months / maxMonths);
    double dy(double v) => size.height * (1 - (v - minY) / (maxY - minY));

    // Grille verticale (tous les 12 mois).
    final grid = Paint()..color = Colors.grey.shade200..strokeWidth = 1;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int m = 0; m <= maxMonths; m += 12) {
      canvas.drawLine(Offset(dx(m), 0), Offset(dx(m), size.height), grid);
      tp.text = TextSpan(text: '${m}m', style: const TextStyle(fontSize: 8, color: Colors.grey));
      tp.layout();
      tp.paint(canvas, Offset(dx(m) + 2, size.height - 10));
    }

    // Couloirs de référence.
    void drawBand(double z, Color color) {
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      final path = Path();
      bool started = false;
      for (int m = 0; m <= maxMonths; m++) {
        final v = GrowthService.valueForZ(indicator: indicator, sex: child.sex, ageMonths: m, z: z);
        if (v == null) continue;
        final o = Offset(dx(m), dy(v));
        if (!started) {
          path.moveTo(o.dx, o.dy);
          started = true;
        } else {
          path.lineTo(o.dx, o.dy);
        }
      }
      canvas.drawPath(path, paint);
    }

    drawBand(-3, Colors.red.shade300);
    drawBand(-2, Colors.orange.shade300);
    drawBand(0, Colors.green.shade400);
    drawBand(2, Colors.orange.shade300);
    drawBand(3, Colors.red.shade300);

    // Points de l'enfant reliés.
    final childPaint = Paint()
      ..color = const Color(0xFF4693D4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dotPaint = Paint()..color = const Color(0xFF4693D4);
    Offset? prev;
    for (final meas in measurements) {
      final v = meas.valueFor(indicator);
      if (v == null) continue;
      final months = _ageMonths(child.birthDate, meas.date);
      if (months > maxMonths) continue;
      final o = Offset(dx(months), dy(v));
      if (prev != null) canvas.drawLine(prev, o, childPaint);
      canvas.drawCircle(o, 3.5, dotPaint);
      prev = o;
    }
  }

  int _ageMonths(DateTime birth, DateTime at) {
    int m = (at.year - birth.year) * 12 + (at.month - birth.month);
    if (at.day < birth.day) m -= 1;
    return m < 0 ? 0 : m;
  }

  @override
  bool shouldRepaint(covariant _GrowthChartPainter old) =>
      old.indicator != indicator || old.measurements != measurements || old.child != child;
}

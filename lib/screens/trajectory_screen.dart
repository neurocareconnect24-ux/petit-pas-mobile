import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../services/content_service.dart';

class TrajectoryScreen extends StatelessWidget {
  final Child activeChild;
  final Map<String, MilestoneRecord> records;

  const TrajectoryScreen({
    super.key,
    required this.activeChild,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final totalMilestones = ContentService.milestones.length;
    final achievedCount = records.values.where((r) => r.status == MilestoneStatus.achieved).length;
    final pendingCount = records.values.where((r) => isToFollow(r.status)).length;
    final progressPercent = totalMilestones > 0 ? (achievedCount / totalMilestones) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte résumé de progression
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trajectoire de ${activeChild.name}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F0FA),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(progressPercent * 100).toInt()}% évalué',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4693D4)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF39A773), // Vert pour la progression
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        label: 'Acquis',
                        value: '$achievedCount',
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                      _StatItem(
                        label: 'En attente',
                        value: '$pendingCount',
                        color: Colors.orange,
                        icon: Icons.hourglass_bottom,
                      ),
                      _StatItem(
                        label: 'Total base',
                        value: '$totalMilestones',
                        color: Colors.blue,
                        icon: Icons.list_alt,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Explication pédagogique
          Card(
            color: Colors.blue.shade50,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Chaque enfant se développe à son propre rythme. Les repères temporels sont des tranches moyennes et non des échéances rigides.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
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

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

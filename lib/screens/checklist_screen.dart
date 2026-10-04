import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../models/red_flag.dart';
import '../services/content_service.dart';
import '../data/i18n_data.dart';
import '../services/audio_service.dart';

class ChecklistScreen extends StatefulWidget {
  final Child activeChild;
  final Map<String, MilestoneRecord> records;
  final Function(String milestoneId, MilestoneStatus status) onUpdateRecord;

  const ChecklistScreen({
    super.key,
    required this.activeChild,
    required this.records,
    required this.onUpdateRecord,
  });

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  late String _selectedBracket;
  Domain? _selectedDomain;

  final List<String> _brackets = ['2m', '4m', '6m', '9m', '12m', '15m', '18m', '24m', '30m', '36m', '48m', '60m'];

  @override
  void initState() {
    super.initState();
    _selectedBracket = AgeCalculation.fromChild(widget.activeChild).currentAgeBracket;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.activeChild.language;
    final t = UiTranslations.all[lang] ?? UiTranslations.all[Language.fr]!;
    
    var filteredMilestones = ContentService.milestones.where((m) => m.ageBracket == _selectedBracket).toList();
    if (_selectedDomain != null) {
      filteredMilestones = filteredMilestones.where((m) => m.domain == _selectedDomain).toList();
    }

    final age = AgeCalculation.fromChild(widget.activeChild);
    final applicableRedFlags = ContentService.redFlags.where((rf) => rf.appliesAt(age.correctedMonths)).toList();

    return Column(
      children: [
        // Filtre horizontal des tranches d'âge
        Container(
          height: 50,
          color: Colors.white,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _brackets.length,
            itemBuilder: (context, index) {
              final bracket = _brackets[index];
              final isSelected = bracket == _selectedBracket;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(bracket, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE1F0FA),
                  checkmarkColor: const Color(0xFF4693D4),
                  onSelected: (selected) {
                    setState(() => _selectedBracket = bracket);
                  },
                ),
              );
            },
          ),
        ),

        // Filtre de domaine
        Container(
          height: 50,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: const Text('Tous les domaines'),
                  selected: _selectedDomain == null,
                  onSelected: (_) => setState(() => _selectedDomain = null),
                ),
              ),
              ...Domain.values.map((d) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(d.getTitle(lang)),
                  selected: _selectedDomain == d,
                  onSelected: (_) => setState(() => _selectedDomain = d),
                ),
              )),
            ],
          ),
        ),

        // Liste des jalons
        Expanded(
          child: filteredMilestones.isEmpty
              ? const Center(child: Text('Aucun jalon répertorié pour ces filtres.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMilestones.length,
                  itemBuilder: (context, index) {
                    final milestone = filteredMilestones[index];
                    final record = widget.records[milestone.id];
                    final status = record?.status ?? MilestoneStatus.unknown;
                    final text = milestone.text[lang] ?? milestone.text[Language.fr] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: milestone.isWatchItem ? Colors.amber.shade300 : Colors.grey.shade200,
                          width: milestone.isWatchItem ? 1.5 : 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (milestone.isWatchItem)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8.0),
                                    child: Tooltip(
                                      message: 'Item à surveiller',
                                      child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Color(0xFF141414),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up, color: Color(0xFF4693D4)),
                                  onPressed: () {
                                    AudioService.speakText(
                                      text: text,
                                      language: lang,
                                      id: milestone.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Boutons d'état (Acquis / Parfois / En cours)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: status == MilestoneStatus.achieved ? Colors.green.shade50 : Colors.transparent,
                                      side: BorderSide(color: status == MilestoneStatus.achieved ? Colors.green : Colors.grey.shade300),
                                    ),
                                    onPressed: () => widget.onUpdateRecord(milestone.id, MilestoneStatus.achieved),
                                    child: Text(
                                      t.achieved,
                                      style: TextStyle(
                                        color: status == MilestoneStatus.achieved ? Colors.green.shade800 : Colors.grey.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: status == MilestoneStatus.emerging ? Colors.amber.shade50 : Colors.transparent,
                                      side: BorderSide(color: status == MilestoneStatus.emerging ? Colors.amber : Colors.grey.shade300),
                                    ),
                                    onPressed: () => widget.onUpdateRecord(milestone.id, MilestoneStatus.emerging),
                                    child: Text(
                                      'Parfois',
                                      style: TextStyle(
                                        color: status == MilestoneStatus.emerging ? Colors.amber.shade900 : Colors.grey.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      backgroundColor: status == MilestoneStatus.notYet ? Colors.orange.shade50 : Colors.transparent,
                                      side: BorderSide(color: status == MilestoneStatus.notYet ? Colors.orange : Colors.grey.shade300),
                                    ),
                                    onPressed: () => widget.onUpdateRecord(milestone.id, MilestoneStatus.notYet),
                                    child: Text(
                                      t.notYet,
                                      style: TextStyle(
                                        color: status == MilestoneStatus.notYet ? Colors.orange.shade900 : Colors.grey.shade700,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (isToFollow(status)) ...[
                              Builder(builder: (context) {
                                final activities = ContentService.activities
                                    .where((a) => a.milestoneIds.contains(milestone.id))
                                    .take(2)
                                    .toList();
                                if (activities.isEmpty) return const SizedBox();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    const Text("Activités pour l'aider :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    const SizedBox(height: 8),
                                    ...activities.map((a) {
                                      final aTitle = a.title[lang] ?? a.title[Language.fr] ?? '';
                                      final aDesc = a.description[lang] ?? a.description[Language.fr] ?? '';
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(aTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                                  Text(aDesc, style: const TextStyle(fontSize: 11)),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                              icon: const Icon(Icons.volume_up, size: 16, color: Colors.blue),
                                              onPressed: () => AudioService.speakText(text: "$aTitle. $aDesc", language: lang, id: a.id),
                                            )
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Red Flags
        if (applicableRedFlags.isNotEmpty)
          ExpansionTile(
            title: const Text("Signes d'alerte, quel que soit l'âge", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            children: applicableRedFlags.map((rf) {
              final isUrgent = rf.urgency == RedFlagUrgency.urgent;
              final text = rf.text[lang] ?? rf.text[Language.fr] ?? '';
              return ListTile(
                leading: Icon(Icons.warning, color: isUrgent ? Colors.red : Colors.amber),
                title: Text(text),
                subtitle: Text(
                  isUrgent ? 'Consulter sans attendre' : 'En parler rapidement à un soignant',
                  style: TextStyle(color: isUrgent ? Colors.red : Colors.amber.shade900, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

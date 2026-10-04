import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../services/content_service.dart';
import '../services/audio_service.dart';

class ActivitiesScreen extends StatefulWidget {
  final Child activeChild;

  const ActivitiesScreen({
    super.key,
    required this.activeChild,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
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

    var filteredActivities = ContentService.activities.where((a) => a.ageBracket == _selectedBracket).toList();
    if (_selectedDomain != null) {
      filteredActivities = filteredActivities.where((a) => a.domain == _selectedDomain).toList();
    }

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

        Expanded(
          child: filteredActivities.isEmpty
              ? const Center(child: Text('Aucune activité répertoriée pour ces filtres.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredActivities.length,
                  itemBuilder: (context, index) {
                    final activity = filteredActivities[index];
                    final title = activity.title[lang] ?? activity.title[Language.fr] ?? '';
                    final description = activity.description[lang] ?? activity.description[Language.fr] ?? '';
                    final materials = activity.materials[lang] ?? activity.materials[Language.fr] ?? [];
                    final tip = activity.parentTip[lang] ?? activity.parentTip[Language.fr] ?? '';
                    
                    final duration = activity.duration?[lang] ?? activity.duration?[Language.fr];
                    final easier = activity.easier?[lang] ?? activity.easier?[Language.fr];
                    final harder = activity.harder?[lang] ?? activity.harder?[Language.fr];
                    final safety = activity.safety?[lang] ?? activity.safety?[Language.fr];

                    final relatedMilestones = ContentService.milestones
                        .where((m) => activity.milestoneIds.contains(m.id))
                        .map((m) => m.text[lang] ?? m.text[Language.fr] ?? '')
                        .toList();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Chip(
                                  label: Text(
                                    'Âge: ${activity.ageBracket}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF4693D4)),
                                  ),
                                  backgroundColor: const Color(0xFFE1F0FA),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.volume_up, color: Color(0xFF4693D4)),
                                  onPressed: () {
                                    final speechText = StringBuffer('$title. $description.');
                                    if (duration != null) speechText.write(' Durée: $duration.');
                                    if (easier != null) speechText.write(' Plus simple: $easier.');
                                    if (harder != null) speechText.write(' Pour aller plus loin: $harder.');
                                    if (safety != null) speechText.write(' Sécurité: $safety.');
                                    if (relatedMilestones.isNotEmpty) {
                                      speechText.write(' Jalons travaillés: ${relatedMilestones.join(", ")}.');
                                    }
                                    AudioService.speakText(
                                      text: speechText.toString(),
                                      language: lang,
                                      id: activity.id,
                                    );
                                  },
                                ),
                              ],
                            ),
                            Text(
                              title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (duration != null) 
                              Text('⏱ $duration', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(color: Colors.black87, fontSize: 13),
                            ),
                            const SizedBox(height: 12),

                            if (easier != null) ...[
                              const Text('Plus simple :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(easier, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                            ],
                            
                            if (harder != null) ...[
                              const Text('Pour aller plus loin :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(harder, style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                            ],

                            // Matériel nécessaire
                            if (materials.isNotEmpty) ...[
                              const Text('Matériel recommandé :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: materials
                                    .map(
                                      (m) => Chip(
                                        avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                                        label: Text(m, style: const TextStyle(fontSize: 11)),
                                        backgroundColor: const Color(0xFFFFFFFF), // sand-100
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            if (safety != null) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.warning, color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Sécurité :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.red)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(safety, style: const TextStyle(fontSize: 12, color: Colors.red)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Conseil parent
                            if (tip.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.all(10),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        tip,
                                        style: const TextStyle(fontSize: 11, color: Colors.brown),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            if (relatedMilestones.isNotEmpty) ...[
                              const Text('Jalons travaillés :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              ...relatedMilestones.map((mText) => Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text('• $mText', style: const TextStyle(fontSize: 11)),
                              )),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../models/growth.dart';
import '../services/storage_service.dart';
import '../services/alert_service.dart';
import '../widgets/header_bar.dart';
import '../widgets/child_modal.dart';
import '../widgets/alert_banner.dart';
import 'checklist_screen.dart';
import 'trajectory_screen.dart';
import 'growth_screen.dart';
import 'activities_screen.dart';
import 'assistant_screen.dart';
import 'consultation_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Child> _children = [];
  Child? _activeChild;
  Map<String, MilestoneRecord> _records = {};
  List<GrowthMeasurement> _measurements = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final children = await StorageService.getChildren();
    final activeId = await StorageService.getActiveChildId();
    final active = children.firstWhere((c) => c.id == activeId, orElse: () => children.first);
    final records = await StorageService.getMilestoneRecords(active.id);
    final measurements = await StorageService.getMeasurements(active.id);

    setState(() {
      _children = children;
      _activeChild = active;
      _records = records;
      _measurements = measurements;
      _isLoading = false;
    });
  }

  void _onSelectChild(String id) async {
    await StorageService.setActiveChildId(id);
    final active = _children.firstWhere((c) => c.id == id);
    final records = await StorageService.getMilestoneRecords(id);
    final measurements = await StorageService.getMeasurements(id);

    setState(() {
      _activeChild = active;
      _records = records;
      _measurements = measurements;
    });
  }

  void _onSaveChild(Child child) async {
    final index = _children.indexWhere((c) => c.id == child.id);
    if (index >= 0) {
      _children[index] = child;
    } else {
      _children.add(child);
    }
    await StorageService.saveChildren(_children);
    _onSelectChild(child.id);
  }

  void _onUpdateRecord(String milestoneId, MilestoneStatus status) async {
    if (_activeChild == null) return;
    final updated = await StorageService.saveMilestoneStatus(
      childId: _activeChild!.id,
      milestoneId: milestoneId,
      status: status,
    );
    setState(() {
      _records[milestoneId] = updated;
    });
  }

  void _openChildModal({Child? child}) {
    showDialog(
      context: context,
      builder: (context) => ChildModal(
        initialChild: child,
        currentLanguage: _activeChild?.language ?? Language.fr,
        onSave: _onSaveChild,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _activeChild == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF4693D4))),
      );
    }

    // Évaluation des signaux de vigilance (jalons + croissance) pour l'enfant actif.
    final alertReport = AlertService.evaluate(
      _activeChild!,
      _records,
      measurements: _measurements,
    );

    final pages = [
      ChecklistScreen(
        activeChild: _activeChild!,
        records: _records,
        onUpdateRecord: _onUpdateRecord,
      ),
      TrajectoryScreen(
        activeChild: _activeChild!,
        records: _records,
      ),
      GrowthScreen(
        activeChild: _activeChild!,
        onMeasurementsChanged: (list) => setState(() => _measurements = list),
      ),
      ActivitiesScreen(
        activeChild: _activeChild!,
      ),
      AssistantScreen(
        activeChild: _activeChild!,
        records: _records,
      ),
      ConsultationScreen(
        activeChild: _activeChild!,
        records: _records,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: HeaderBar(
        childrenList: _children,
        activeChild: _activeChild!,
        onSelectChild: _onSelectChild,
        onOpenAddChild: () => _openChildModal(),
        onOpenEditChild: () => _openChildModal(child: _activeChild),
        onLanguageChange: (lang) {
          final updated = Child(
            id: _activeChild!.id,
            name: _activeChild!.name,
            birthDate: _activeChild!.birthDate,
            sex: _activeChild!.sex,
            isPremature: _activeChild!.isPremature,
            gestationalWeeks: _activeChild!.gestationalWeeks,
            language: lang,
          );
          _onSaveChild(updated);
        },
      ),
      body: Column(
        children: [
          // La bannière de vigilance est masquée sur l'onglet RDV (redondant).
          if (_currentIndex != 5)
            AlertBanner(
              report: alertReport,
              language: _activeChild!.language,
              onOpenConsultation: () => setState(() => _currentIndex = 5),
            ),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF4693D4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.check_box_outlined), label: 'Jalons'),
          const BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Trajectoire'),
          const BottomNavigationBarItem(icon: Icon(Icons.monitor_weight_outlined), label: 'Croissance'),
          const BottomNavigationBarItem(icon: Icon(Icons.extension_outlined), label: 'Activités'),
          const BottomNavigationBarItem(icon: Icon(Icons.smart_toy_outlined), label: 'Assistant'),
          BottomNavigationBarItem(
            icon: _NavBadge(
              count: alertReport.highCount,
              child: const Icon(Icons.calendar_today_outlined),
            ),
            label: 'RDV',
          ),
        ],
      ),
    );
  }
}

/// Icône de navigation avec pastille rouge indiquant le nombre de signaux
/// d'alerte de gravité haute (0 = pas de pastille).
class _NavBadge extends StatelessWidget {
  final int count;
  final Widget child;
  const _NavBadge({required this.count, required this.child});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return child;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Color(0xFFD32F2F),
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              '$count',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}

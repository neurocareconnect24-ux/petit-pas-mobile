import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child.dart';
import '../models/milestone.dart';
import '../models/chat_message.dart';
import '../models/growth.dart';

class StorageService {
  static const String keyChildren = 'nct_children_v1';
  static const String keyActiveChildId = 'nct_active_child_id_v1';
  static const String keyMilestonesPrefix = 'nct_milestones_';
  static const String keyChatPrefix = 'nct_chat_';
  static const String keyGrowthPrefix = 'nct_growth_';

  static Child get sampleChild => Child(
        id: 'child_default_1',
        name: 'Koffi',
        birthDate: DateTime.now().subtract(const Duration(days: 540)), // ~18 mois
        isPremature: false,
        language: Language.fr,
      );

  /// Récupère la liste de tous les enfants
  static Future<List<Child>> getChildren() async {
    final prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(keyChildren);
    if (raw == null || raw.isEmpty) {
      final defaultList = [sampleChild];
      await saveChildren(defaultList);
      return defaultList;
    }
    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      return jsonList.map((e) => Child.fromJson(e)).toList();
    } catch (e) {
      return [sampleChild];
    }
  }

  /// Sauvegarde la liste des enfants
  static Future<void> saveChildren(List<Child> children) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = children.map((c) => c.toJson()).toList();
    await prefs.setString(keyChildren, jsonEncode(jsonList));
  }

  /// Récupère l'ID de l'enfant actif
  static Future<String> getActiveChildId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(keyActiveChildId);
    final children = await getChildren();
    if (id != null && children.any((c) => c.id == id)) {
      return id;
    }
    return children.first.id;
  }

  /// Définit l'enfant actif
  static Future<void> setActiveChildId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyActiveChildId, id);
  }

  /// Récupère les jalons enregistrés pour un enfant
  static Future<Map<String, MilestoneRecord>> getMilestoneRecords(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$keyMilestonesPrefix$childId');
    if (raw == null || raw.isEmpty) return {};

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(raw);
      final Map<String, MilestoneRecord> result = {};
      jsonMap.forEach((key, value) {
        result[key] = MilestoneRecord.fromJson(value);
      });
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Enregistre le statut d'un jalon
  static Future<MilestoneRecord> saveMilestoneStatus({
    required String childId,
    required String milestoneId,
    required MilestoneStatus status,
    String? note,
  }) async {
    final records = await getMilestoneRecords(childId);
    final record = MilestoneRecord(
      childId: childId,
      milestoneId: milestoneId,
      status: status,
      updatedAt: DateTime.now(),
      note: note,
    );
    records[milestoneId] = record;

    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> jsonMap = {};
    records.forEach((key, val) {
      jsonMap[key] = val.toJson();
    });
    await prefs.setString('$keyMilestonesPrefix$childId', jsonEncode(jsonMap));
    return record;
  }

  /// Récupère l'historique du chat pour un enfant
  static Future<List<ChatMessage>> getChatMessages(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$keyChatPrefix$childId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      return jsonList.map((e) => ChatMessage.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Sauvegarde le chat pour un enfant
  static Future<void> saveChatMessages(String childId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((m) => m.toJson()).toList();
    await prefs.setString('$keyChatPrefix$childId', jsonEncode(jsonList));
  }

  /// Récupère les mesures de croissance d'un enfant, triées par date croissante.
  static Future<List<GrowthMeasurement>> getMeasurements(String childId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$keyGrowthPrefix$childId');
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(raw);
      final list = jsonList.map((e) => GrowthMeasurement.fromJson(e)).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    } catch (e) {
      return [];
    }
  }

  /// Ajoute (ou remplace par id) une mesure de croissance.
  static Future<List<GrowthMeasurement>> saveMeasurement(
      GrowthMeasurement measurement) async {
    final list = await getMeasurements(measurement.childId);
    final idx = list.indexWhere((m) => m.id == measurement.id);
    if (idx >= 0) {
      list[idx] = measurement;
    } else {
      list.add(measurement);
    }
    list.sort((a, b) => a.date.compareTo(b.date));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$keyGrowthPrefix${measurement.childId}',
        jsonEncode(list.map((m) => m.toJson()).toList()));
    return list;
  }

  /// Supprime une mesure de croissance.
  static Future<List<GrowthMeasurement>> deleteMeasurement(
      String childId, String measurementId) async {
    final list = await getMeasurements(childId);
    list.removeWhere((m) => m.id == measurementId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        '$keyGrowthPrefix$childId', jsonEncode(list.map((m) => m.toJson()).toList()));
    return list;
  }
}

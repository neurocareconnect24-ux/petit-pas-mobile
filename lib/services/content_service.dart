import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/milestone.dart';
import '../models/activity.dart';
import '../models/red_flag.dart';

class ContentService {
  static const _cacheKey = 'pp_content_v1';
  static List<Milestone> milestones = [];
  static List<Activity> activities = [];
  static List<RedFlag> redFlags = [];

  /// À appeler dans main() avant runApp.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    _apply(jsonDecode(cached ?? await rootBundle.loadString('assets/content_fallback.json')));
    refresh(); // mise à jour en arrière-plan, sans bloquer le démarrage
  }

  static Future<void> refresh() async {
    try {
      final res = await http
          .get(Uri.parse('https://track.bonkano.fr/api/content'))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return;
      final body = utf8.decode(res.bodyBytes);
      _apply(jsonDecode(body));
      (await SharedPreferences.getInstance()).setString(_cacheKey, body);
    } catch (_) {
      // hors ligne : on garde le cache
    }
  }

  static void _apply(Map<String, dynamic> json) {
    milestones = (json['milestones'] as List).map((e) => Milestone.fromJson(e)).toList();
    activities = (json['activities'] as List).map((e) => Activity.fromJson(e)).toList();
    redFlags = (json['redFlags'] as List).map((e) => RedFlag.fromJson(e)).toList();
  }
}

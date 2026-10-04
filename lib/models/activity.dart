import 'child.dart';
import 'milestone.dart';

class Activity {
  final String id;
  final String ageBracket;
  final Domain domain;
  final Map<Language, String> title;
  final Map<Language, String> description;
  final Map<Language, List<String>> materials;
  final Map<Language, String> parentTip;
  final List<String> milestoneIds;
  final Map<Language, String>? duration;
  final Map<Language, String>? easier;
  final Map<Language, String>? harder;
  final Map<Language, String>? safety;

  Activity({
    required this.id,
    required this.ageBracket,
    required this.domain,
    required this.title,
    required this.description,
    required this.materials,
    required this.parentTip,
    required this.milestoneIds,
    this.duration,
    this.easier,
    this.harder,
    this.safety,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    Map<Language, List<String>> parseMaterials(Map<String, dynamic>? matJson) {
      final res = <Language, List<String>>{};
      if (matJson != null) {
        for (final l in Language.values) {
          if (matJson[l.code] != null) {
            res[l] = (matJson[l.code] as List).map((e) => e.toString()).toList();
          }
        }
      }
      return res;
    }

    return Activity(
      id: json['id'] as String,
      ageBracket: json['ageBracket'] as String,
      domain: domainFromId(json['domain'] as String),
      milestoneIds: (json['milestoneIds'] as List?)?.map((e) => e as String).toList() ?? [],
      title: localizedFromJson(json['title'] as Map<String, dynamic>?),
      description: localizedFromJson(json['description'] as Map<String, dynamic>?),
      materials: parseMaterials(json['materials'] as Map<String, dynamic>?),
      parentTip: localizedFromJson(json['parentTip'] as Map<String, dynamic>?),
      duration: localizedFromJson(json['duration'] as Map<String, dynamic>?),
      easier: localizedFromJson(json['easier'] as Map<String, dynamic>?),
      harder: localizedFromJson(json['harder'] as Map<String, dynamic>?),
      safety: localizedFromJson(json['safety'] as Map<String, dynamic>?),
    );
  }
}

import 'child.dart';
import 'milestone.dart';

enum RedFlagUrgency { urgent, consult }

class RedFlag {
  final String id;
  final RedFlagUrgency urgency;
  final int? fromMonths;
  final int? toMonths;
  final Map<Language, String> text;
  final Map<Language, String>? detail;

  RedFlag({
    required this.id,
    required this.urgency,
    this.fromMonths,
    this.toMonths,
    required this.text,
    this.detail,
  });

  bool appliesAt(int months) =>
      (fromMonths == null || months >= fromMonths!) &&
      (toMonths == null || months <= toMonths!);

  factory RedFlag.fromJson(Map<String, dynamic> json) {
    return RedFlag(
      id: json['id'] as String,
      urgency: json['urgency'] == 'urgent'
          ? RedFlagUrgency.urgent
          : RedFlagUrgency.consult,
      fromMonths: json['fromMonths'] as int?,
      toMonths: json['toMonths'] as int?,
      text: localizedFromJson(json['text'] as Map<String, dynamic>?),
      detail: localizedFromJson(json['detail'] as Map<String, dynamic>?),
    );
  }
}

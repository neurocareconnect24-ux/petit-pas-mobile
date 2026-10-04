import 'child.dart';

enum Domain { motorGross, motorFine, language, socialPersonal, cognitive }

Domain domainFromId(String id) => Domain.values.firstWhere((d) => d.id == id);

extension DomainExtension on Domain {
  String get id {
    switch (this) {
      case Domain.motorGross:
        return 'motor_gross';
      case Domain.motorFine:
        return 'motor_fine';
      case Domain.language:
        return 'language';
      case Domain.socialPersonal:
        return 'social_personal';
      case Domain.cognitive:
        return 'cognitive';
    }
  }

  String getTitle(Language lang) {
    switch (this) {
      case Domain.motorGross:
        return lang == Language.fon
            ? 'Nukún yiyi kpo afɔ yiyi kpo'
            : lang == Language.yoruba
                ? 'Mọ́tò Gbogbogbo'
                : 'Motricité globale';
      case Domain.motorFine:
        return lang == Language.fon
            ? 'Alɔ zɔ́'
            : lang == Language.yoruba
                ? 'Mọ́tò Kekere'
                : 'Motricité fine';
      case Domain.language:
        return lang == Language.fon
            ? 'Xó ɖìɖɔ kpo toɖíɖó kpo'
            : lang == Language.yoruba
                ? 'Èdè àti Ìbánisọ̀rọ̀'
                : 'Langage & Communication';
      case Domain.socialPersonal:
        return lang == Language.fon
            ? 'GBɛtɔ́ kpo gbɛ̀tɔ́ kpo nɔ̀'
            : lang == Language.yoruba
                ? 'Àwùjọ àti Ara ẹni'
                : 'Social & Personnel';
      case Domain.cognitive:
        return 'Cognition';
    }
  }
}

enum MilestoneStatus { achieved, emerging, notYet, unknown }

bool isToFollow(MilestoneStatus? s) => s == MilestoneStatus.notYet || s == MilestoneStatus.emerging;

Map<Language, String> localizedFromJson(Map<String, dynamic>? json) => {
      if (json != null)
        for (final l in Language.values)
          if (json[l.code] != null) l: json[l.code] as String,
    };

class Milestone {
  final String id;
  final String ageBracket;
  final Domain domain;
  final Map<Language, String> text;
  final Map<Language, String>? description;
  final bool isWatchItem;
  final Map<Language, String>? guidance;

  Milestone({
    required this.id,
    required this.ageBracket,
    required this.domain,
    required this.text,
    this.description,
    this.isWatchItem = false,
    this.guidance,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      ageBracket: json['ageBracket'] as String,
      domain: domainFromId(json['domain'] as String),
      isWatchItem: json['isWatchItem'] as bool? ?? false,
      text: localizedFromJson(json['text'] as Map<String, dynamic>?),
      guidance: localizedFromJson(json['guidance'] as Map<String, dynamic>?),
    );
  }
}

class MilestoneRecord {
  final String childId;
  final String milestoneId;
  final MilestoneStatus status;
  final DateTime updatedAt;
  final String? note;

  MilestoneRecord({
    required this.childId,
    required this.milestoneId,
    required this.status,
    DateTime? updatedAt,
    this.note,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'childId': childId,
        'milestoneId': milestoneId,
        'status': status.name,
        'updatedAt': updatedAt.toIso8601String(),
        'note': note,
      };

  factory MilestoneRecord.fromJson(Map<String, dynamic> json) {
    return MilestoneRecord(
      childId: json['childId'] ?? '',
      milestoneId: json['milestoneId'] ?? '',
      status: MilestoneStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MilestoneStatus.unknown,
      ),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      note: json['note'],
    );
  }
}

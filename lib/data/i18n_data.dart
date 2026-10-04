import '../models/child.dart';

class UiTranslations {
  final String appTitle;
  final String subtitle;
  final String tabChecklist;
  final String tabTrajectory;
  final String tabActivities;
  final String tabAssistant;
  final String tabConsultation;
  final String addChild;
  final String editChild;
  final String name;
  final String birthDate;
  final String prematurity;
  final String gestationalWeeks;
  final String selectLanguage;
  final String save;
  final String cancel;
  final String achieved;
  final String notYet;
  final String askAssistant;
  final String send;
  final String printConsultation;

  UiTranslations({
    required this.appTitle,
    required this.subtitle,
    required this.tabChecklist,
    required this.tabTrajectory,
    required this.tabActivities,
    required this.tabAssistant,
    required this.tabConsultation,
    required this.addChild,
    required this.editChild,
    required this.name,
    required this.birthDate,
    required this.prematurity,
    required this.gestationalWeeks,
    required this.selectLanguage,
    required this.save,
    required this.cancel,
    required this.achieved,
    required this.notYet,
    required this.askAssistant,
    required this.send,
    required this.printConsultation,
  });

  static Map<Language, UiTranslations> all = {
    Language.fr: UiTranslations(
      appTitle: 'Petit Pas',
      subtitle: 'Surveillance développementale (0-5 ans)',
      tabChecklist: 'Jalons',
      tabTrajectory: 'Trajectoire',
      tabActivities: 'Activités',
      tabAssistant: 'Assistant IA',
      tabConsultation: 'Consultation',
      addChild: 'Ajouter un enfant',
      editChild: 'Modifier le profil',
      name: 'Prénom ou Pseudo',
      birthDate: 'Date de naissance',
      prematurity: 'Enfant né prématuré (<37 semaines) ?',
      gestationalWeeks: 'Terme de naissance (semaines)',
      selectLanguage: 'Langue de l’application',
      save: 'Enregistrer',
      cancel: 'Annuler',
      achieved: 'Acquis',
      notYet: 'En cours',
      askAssistant: 'Posez une question sur le développement...',
      send: 'Envoyer',
      printConsultation: 'Synthèse consultation NCC',
    ),
    Language.fon: UiTranslations(
      appTitle: 'Petit Pas',
      subtitle: 'Kpɔ́n vǐ lɛ́ sín nukɔn yiyi (0-5 ans)',
      tabChecklist: 'Nukɔnyiyi',
      tabTrajectory: 'Akwɛ́',
      tabActivities: 'Azɔ̌ lɛ́',
      tabAssistant: 'Gikpɔ́ntɔ́ IA',
      tabConsultation: 'Kplé',
      addChild: 'Gɔ́ vǐ ɖévó',
      editChild: 'Vɔ́ vǐ ɔ́ sín nyíkɔ́',
      name: 'Nyíkɔ́ kabǐ Pseudo',
      birthDate: 'Azǎn e gbe é jɔ́ é',
      prematurity: 'Vǐ ɔ́ jɔ́ ɖò hwenu tɔn gudo á?',
      gestationalWeeks: 'Osun nabi é bló ɖò adɔ̀ mɛ?',
      selectLanguage: 'Gbe e a jró é',
      save: 'Hɛ́n ɖó te',
      cancel: 'Jo é do',
      achieved: 'É kpe',
      notYet: 'É ɖò bló wɛ',
      askAssistant: 'Kan xó ɖé byɔ́ gikpɔ́ntɔ́...',
      send: 'Sɛ́ɖó',
      printConsultation: 'Gbe blesí NCC',
    ),
    Language.yoruba: UiTranslations(
      appTitle: 'Petit Pas',
      subtitle: 'Aṣayan idagbasoke (0-5 ọdun)',
      tabChecklist: 'Àwọn àmì',
      tabTrajectory: 'Ìpa ọ̀nà',
      tabActivities: 'Àwọn iṣẹ́',
      tabAssistant: 'Olùrànlọ́wọ́ IA',
      tabConsultation: 'Ìgbero',
      addChild: 'Fi ọmọ kun',
      editChild: 'Aṣayan ọmọ',
      name: 'Orúkọ tàbí Pseudo',
      birthDate: 'Ọjọ́ ìbí',
      prematurity: 'Ṣé ọmọ wá sí ayé tó tọ́?',
      gestationalWeeks: 'Àwọn ọṣẹ́ inú',
      selectLanguage: 'Èdè rẹ',
      save: 'Fipamọ́',
      cancel: 'Fagilee',
      achieved: 'Aṣeyọri',
      notYet: 'Lóri lọ',
      askAssistant: 'Bère ìbéèrè kan...',
      send: 'Ránṣẹ́',
      printConsultation: 'Aṣayan NCC',
    ),
  };
}

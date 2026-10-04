import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/child.dart';

class ApiService {
  // URL de base du serveur backend NeuroCare Track
  static String baseUrl = 'https://track.bonkano.fr';

  static void setBaseUrl(String url) {
    if (url.endsWith('/')) {
      baseUrl = url.substring(0, url.length - 1);
    } else {
      baseUrl = url;
    }
  }

  /// Envoie un message à l'assistant Gemini 3.6 Flash
  static Future<ChatMessage> sendMessage({
    required String message,
    required Child child,
    required String ageDisplayText,
    required String pendingMilestonesText,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/chat'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'message': message,
              'childName': child.name,
              'childAgeText': ageDisplayText,
              'language': child.language.code,
              'contextMilestones': pendingMilestonesText.isNotEmpty
                  ? pendingMilestonesText
                  : 'Aucun jalon en attente spécifique',
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}_a',
          sender: 'assistant',
          text: data['text'] ??
              'Désolé, je n’ai pas pu générer de réponse. N’hésitez pas à consulter votre médecin.',
          showTeleconsultationCTA: data['showTeleconsultationCTA'] ?? false,
          showExportCTA: data['showExportCTA'] ?? false,
        );
      }
    } catch (e) {
      // Ignore et bascule sur la réponse de secours
    }

    // Réponse de secours si hors-ligne ou erreur serveur
    return ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_f',
      sender: 'assistant',
      text:
          "Merci pour votre observation. Pour des raisons d'information, rappelez-vous que chaque enfant évolue à son propre rythme. Si vous avez la moindre interrogation clinique, n'hésitez pas à solliciter un avis médical ou à prendre rendez-vous en téléconsultation sur NeuroCare Connect (NCC).",
      showTeleconsultationCTA: true,
      showExportCTA: true,
    );
  }

  /// Demande la synthèse vocale au serveur (Gemini TTS)
  static Future<String?> fetchTtsAudioBase64({
    required String text,
    required String languageCode,
    bool isSlow = false,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'language': languageCode,
              'speed': isSlow ? 'slow' : 'normal',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['audioBase64'];
      }
    } catch (e) {
      // Serveur TTS indisponible
    }
    return null;
  }
}

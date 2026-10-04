import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../models/child.dart';
import 'api_service.dart';

class AudioService {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterTts _flutterTts = FlutterTts();
  static bool _isSpeaking = false;
  static String? _currentPlayingId;

  static bool get isSpeaking => _isSpeaking;
  static String? get currentPlayingId => _currentPlayingId;

  static Future<void> init() async {
    _audioPlayer.onPlayerComplete.listen((_) {
      _isSpeaking = false;
      _currentPlayingId = null;
    });
  }

  /// Lit un texte à haute voix en Français, Fon ou Yoruba
  static Future<void> speakText({
    required String text,
    required Language language,
    String? id,
    bool isSlow = false,
  }) async {
    // Si la même lecture est déjà en cours, on l'arrête
    if (_isSpeaking && _currentPlayingId == id) {
      await stop();
      return;
    }

    await stop();

    _isSpeaking = true;
    _currentPlayingId = id;

    try {
      // 1. Essai avec l'API Gemini Neural TTS du serveur backend
      final String? base64Audio = await ApiService.fetchTtsAudioBase64(
        text: text,
        languageCode: language.code,
        isSlow: isSlow,
      );

      if (base64Audio != null && base64Audio.isNotEmpty) {
        final bytes = base64Decode(base64Audio);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/tts_temp_${DateTime.now().millisecondsSinceEpoch}.wav');
        await tempFile.writeAsBytes(bytes);

        await _audioPlayer.play(DeviceFileSource(tempFile.path));
        return;
      }
    } catch (e) {
      if (kDebugMode) print('Erreur Gemini TTS, bascule vers FlutterTTS natif');
    }

    // 2. Fallback avec le moteur de synthèse locale FlutterTTS
    try {
      String locale = 'fr-FR';
      if (language == Language.yoruba) {
        locale = 'yo-NG';
      } else if (language == Language.fon) {
        locale = 'fr-BJ'; // Fallback béninois
      }

      await _flutterTts.setLanguage(locale);
      await _flutterTts.setSpeechRate(isSlow ? 0.35 : 0.5);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.speak(text);

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        _currentPlayingId = null;
      });
    } catch (e) {
      _isSpeaking = false;
      _currentPlayingId = null;
    }
  }

  /// Arrête la lecture audio
  static Future<void> stop() async {
    await _audioPlayer.stop();
    await _flutterTts.stop();
    _isSpeaking = false;
    _currentPlayingId = null;
  }
}

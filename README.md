# 📱 NeuroCare Track Mobile (Flutter App)

Application mobile natif Android et iOS pour la surveillance développementale (0-5 ans) et l'éducation parentale par **Bonkano SASU / NeuroCare Connect (NCC)**.

---

## 🌟 Fonctionnalités Principales

- **Suivi des jalons CDC (0-5 ans)** : Motricité globale, motricité fine, langage, social/personnel.
- **Support multilingue local** : Français, Fon (Fɔ̀ngbe) et Yoruba.
- **Synthèse vocale hybride (TTS)** : Utilisation de Gemini 3.1 Flash Neural TTS avec fallback natif offline.
- **Assistant conversationnel IA** : Intégration directe de Gemini 3.6 Flash avec garde-fous éthiques.
- **Activités ludiques de stimulation** : Jeux adaptés utilisant le matériel quotidien africain (calebasses, chiffons, chansons).
- **Préparation de consultation** : Bilan exportable pour médecin ou téléconsultation NCC.

---

## 🚀 Installation & Exécution

### Prérequis
- Flutter SDK (>= 3.0.0)
- Java 17 / Android Studio (pour compiler l'APK Android)
- macOS & Xcode (pour compiler l'application iOS)

### Étapes

1. **Cloner ou ouvrir le dossier** :
   ```bash
   cd /var/www/neurocare-track-mobile
   ```

2. **Récupérer les dépendances Flutter** :
   ```bash
   flutter pub get
   ```

3. **Lancer sur un émulateur ou appareil connecté** :
   ```bash
   flutter run
   ```

4. **Générer le fichier APK Android pour le serveur** :
   ```bash
   flutter build apk --release
   ```
   *L'APK sera généré dans `build/app/outputs/flutter-apk/app-release.apk`.*

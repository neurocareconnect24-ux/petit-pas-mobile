class ChatMessage {
  final String id;
  final String sender; // 'user' ou 'assistant'
  final String text;
  final DateTime timestamp;
  final bool showTeleconsultationCTA;
  final bool showExportCTA;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    DateTime? timestamp,
    this.showTeleconsultationCTA = false,
    this.showExportCTA = false,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'sender': sender,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
        'showTeleconsultationCTA': showTeleconsultationCTA,
        'showExportCTA': showExportCTA,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      sender: json['sender'] ?? 'user',
      text: json['text'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      showTeleconsultationCTA: json['showTeleconsultationCTA'] ?? false,
      showExportCTA: json['showExportCTA'] ?? false,
    );
  }
}

import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/chat_message.dart';
import '../models/milestone.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../data/i18n_data.dart';
import '../services/content_service.dart';

class AssistantScreen extends StatefulWidget {
  final Child activeChild;
  final Map<String, MilestoneRecord> records;

  const AssistantScreen({
    super.key,
    required this.activeChild,
    required this.records,
  });

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Message de bienvenue initial du guide IA
    _messages.add(
      ChatMessage(
        id: 'welcome',
        sender: 'assistant',
        text: 'Bonjour ! Je suis l’assistant éducatif Petit Pas. Je suis là pour vous informer sur le développement de ${widget.activeChild.name} (0-5 ans). Comment puis-je vous aider aujourd’hui ?',
      ),
    );
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final userMsg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}_u',
      sender: 'user',
      text: text,
    );

    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
      _controller.clear();
    });

    final age = AgeCalculation.fromChild(widget.activeChild);

    // Jalons marqués « pas encore acquis » pour cet enfant.
    final lang = widget.activeChild.language;
    final byId = {for (final m in ContentService.milestones) m.id: m};
    final validRecords = widget.records.values.where((r) => byId.containsKey(r.milestoneId)).toList();
    
    final pending = validRecords
        .where((r) => isToFollow(r.status))
        .map((r) {
          final m = byId[r.milestoneId]!;
          return m.text[lang] ?? m.text[Language.fr] ?? '';
        })
        .where((t) => t.isNotEmpty)
        .toList();

    final assistantMsg = await ApiService.sendMessage(
      message: text,
      child: widget.activeChild,
      ageDisplayText: age.displayText,
      pendingMilestonesText: pending.join(' ; '),
    );

    if (mounted) {
      setState(() {
        _messages.add(assistantMsg);
        _isLoading = false;
      });

      // Vocalisation automatique de la réponse
      AudioService.speakText(
        text: assistantMsg.text,
        language: widget.activeChild.language,
        id: assistantMsg.id,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = UiTranslations.all[widget.activeChild.language] ?? UiTranslations.all[Language.fr]!;

    return Column(
      children: [
        // Avertissement éthique
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.amber.shade100,
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.brown, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cet assistant donne des conseils d’éducation et de stimulation. Il ne pose aucun diagnostic médical.',
                  style: TextStyle(fontSize: 11, color: Colors.brown),
                ),
              ),
            ],
          ),
        ),

        // Historique des messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              final isUser = msg.sender == 'user';

              return Align(
                alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                  decoration: BoxDecoration(
                    color: isUser ? const Color(0xFF4693D4) : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.text,
                        style: TextStyle(
                          color: isUser ? Colors.white : const Color(0xFF141414),
                          fontSize: 14,
                        ),
                      ),
                      if (!isUser) ...[
                        const SizedBox(height: 6),
                        IconButton(
                          alignment: Alignment.centerLeft,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.volume_up, color: Color(0xFF4693D4), size: 20),
                          onPressed: () {
                            AudioService.speakText(
                              text: msg.text,
                              language: widget.activeChild.language,
                              id: msg.id,
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: CircularProgressIndicator(color: Color(0xFF4693D4)),
          ),

        // Zone de saisie
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: t.askAssistant,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF4693D4),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 20),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../shared/widgets/message_bubble.dart';
import 'package:provider/provider.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';
import '../../shared/services/api_client.dart';
import '../settings/settings_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<_Message> _messages = <_Message>[
    const _Message(role: 'assistant', text: 'Hi! I\'m Insight Mate. How can I help?'),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Message(role: 'user', text: text));
      _controller.clear();
      _sending = true;
    });
    String reply = '';
    try {
      final settings = context.read<SettingsController>();
      final apiKey = settings.aiProvider == 'gemini' ? settings.geminiApiKey : settings.openaiApiKey;
      
      reply = await ApiClient().chat(
        messages: [
          for (final m in _messages) {'role': m.role, 'content': m.text},
          {'role': 'user', 'content': text},
        ],
        provider: settings.aiProvider,
        apiKey: apiKey,
      );
    } catch (_) {
      reply = 'Echo: $text';
    }
    setState(() {
      _messages.add(_Message(role: 'assistant', text: reply));
      _sending = false;
    });
    if (!mounted) return;
    await context.read<HistoryService>().add(HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: HistoryType.chat,
      title: 'Chat',
      detail: text,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final isUser = m.role == 'user';
              return MessageBubble(
                text: m.text,
                isUser: isUser,
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: const Text('Send'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Message {
  const _Message({required this.role, required this.text});
  final String role;
  final String text;
}



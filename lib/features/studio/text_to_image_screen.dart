import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/services/history_service.dart';
import '../../shared/models/history_item.dart';
import '../../shared/services/api_client.dart';

class TextToImageScreen extends StatefulWidget {
  const TextToImageScreen({super.key});

  @override
  State<TextToImageScreen> createState() => _TextToImageScreenState();
}

class _TextToImageScreenState extends State<TextToImageScreen> {
  final TextEditingController _prompt = TextEditingController();
  bool _loading = false;
  String? _imageUrl;

  Future<void> _generate() async {
    final text = _prompt.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _loading = true;
      _imageUrl = null;
    });
    String url;
    try {
      url = await ApiClient().generateImage(text);
    } catch (_) {
      url = 'https://picsum.photos/seed/${Uri.encodeComponent(text)}/512/512';
    }
    setState(() {
      _imageUrl = url;
      _loading = false;
    });
    if (!mounted) return;
    final history = context.read<HistoryService>();
    await history.add(HistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: HistoryType.generation,
      title: 'Generated image',
      detail: text,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      extra: {'imageUrl': _imageUrl},
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _prompt,
            decoration: const InputDecoration(
              labelText: 'Enter prompt',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _generate(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _loading ? null : _generate,
                child: const Text('Generate'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : _imageUrl == null
                      ? const Text('Image will appear here')
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(_imageUrl!, fit: BoxFit.cover),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}



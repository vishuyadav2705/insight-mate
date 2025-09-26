import 'package:flutter/material.dart';
import '../../shared/services/tts_service.dart';
import '../../shared/services/stt_service.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({super.key});

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> {
  bool _listening = false;
  String _transcript = '';
  final TtsService _tts = TtsService();
  final SttService _stt = SttService();

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _tts.configure();
    await _stt.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice to Text', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(_transcript.isEmpty ? 'Press mic to start listening' : _transcript),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () async {
                  if (_listening) {
                    await _stt.stop();
                    setState(() => _listening = false);
                  } else {
                    setState(() {
                      _transcript = '';
                      _listening = true;
                    });
                    await _stt.listen(onResult: (text) {
                      setState(() => _transcript = text);
                    });
                  }
                },
                icon: Icon(_listening ? Icons.stop : Icons.mic),
                label: Text(_listening ? 'Stop' : 'Start'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _transcript.isEmpty
                    ? null
                    : () async {
                        await _tts.speak(_transcript);
                      },
                icon: const Icon(Icons.volume_up),
                label: const Text('Speak'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



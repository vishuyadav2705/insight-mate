import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  SttService() : _speech = stt.SpeechToText();

  final stt.SpeechToText _speech;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    return _speech.initialize();
  }

  Future<void> listen({required void Function(String text) onResult}) async {
    await _speech.listen(onResult: (result) {
      onResult(result.recognizedWords);
    });
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}



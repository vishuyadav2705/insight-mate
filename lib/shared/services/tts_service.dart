import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  TtsService() : _tts = FlutterTts();

  final FlutterTts _tts;

  Future<void> configure({double rate = 0.5, double pitch = 1.0}) async {
    await _tts.setSpeechRate(rate);
    await _tts.setPitch(pitch);
    await _tts.setVolume(1.0);
  }

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}



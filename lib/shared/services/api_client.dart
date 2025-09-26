import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String get _base => EnvConfig.backendBaseUrl;

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<String> chat(List<Map<String, String>> messages) async {
    final res = await _http.post(
      _uri('/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['reply'] as String?) ?? '';
    }
    throw Exception('Chat failed: ${res.statusCode}');
  }

  Future<String> generateImage(String prompt) async {
    final res = await _http.post(
      _uri('/api/images/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'prompt': prompt}),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['url'] as String?) ?? '';
    }
    throw Exception('Image generation failed: ${res.statusCode}');
  }
}



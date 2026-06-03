import 'dart:convert';
import 'package:http/http.dart' as http;
import 'env.dart';

class ApiClient {
  ApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  String get _base => EnvConfig.backendBaseUrl;

  Uri _uri(String path) => Uri.parse('$_base$path');

  Future<String> chat({
    required List<Map<String, String>> messages,
    String? provider,
    String? apiKey,
  }) async {
    final res = await _http.post(
      _uri('/api/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'messages': messages,
        if (provider != null) 'provider': provider,
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
      }),
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

  Future<Map<String, dynamic>> barcodeLookup(String code, {String? apiKey}) async {
    final res = await _http.post(
      _uri('/api/barcode/lookup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'code': code,
        if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
      }),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Barcode lookup failed: ${res.statusCode}');
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final res = await _http.get(_uri('/api/history'));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = jsonDecode(res.body) as List<dynamic>;
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Fetch history failed: ${res.statusCode}');
  }

  Future<void> saveHistory(Map<String, dynamic> item) async {
    final res = await _http.post(
      _uri('/api/history'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(item),
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Save history failed: ${res.statusCode}');
    }
  }
}

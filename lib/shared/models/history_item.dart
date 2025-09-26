import 'dart:convert';

enum HistoryType { chat, scan, generation, imageSearch }

class HistoryItem {
  HistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.detail,
    required this.timestampMs,
    this.extra,
  });

  final String id;
  final HistoryType type;
  final String title;
  final String detail;
  final int timestampMs;
  final Map<String, Object?>? extra;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'type': type.name,
        'title': title,
        'detail': detail,
        'timestampMs': timestampMs,
        'extra': extra,
      };

  static HistoryItem fromJson(Map<String, Object?> map) => HistoryItem(
        id: map['id'] as String,
        type: HistoryType.values.firstWhere((e) => e.name == map['type'] as String),
        title: map['title'] as String,
        detail: map['detail'] as String,
        timestampMs: (map['timestampMs'] as num).toInt(),
        extra: (map['extra'] as Map?)?.cast<String, Object?>(),
      );

  static List<HistoryItem> decodeList(String jsonStr) {
    final list = json.decode(jsonStr) as List<dynamic>;
    return list.cast<Map<String, Object?>>().map(fromJson).toList();
  }

  static String encodeList(List<HistoryItem> items) {
    return json.encode(items.map((e) => e.toJson()).toList());
  }
}



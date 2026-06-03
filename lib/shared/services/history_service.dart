import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';
import 'api_client.dart';

class HistoryService extends ChangeNotifier {
  HistoryService(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'history_items_v1';

  List<HistoryItem> _items = <HistoryItem>[];
  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _items = HistoryItem.decodeList(raw);
        notifyListeners();
      } catch (err) {
        debugPrint('Error decoding local history: $err');
      }
    }

    final syncEnabled = _prefs.getBool('syncToCloud') ?? false;
    if (syncEnabled) {
      try {
        final cloudItems = await ApiClient().fetchHistory();
        final parsed = cloudItems.map((e) {
          final typeStr = e['type'] as String? ?? 'chat';
          final hType = HistoryType.values.firstWhere(
            (t) => t.name == typeStr,
            orElse: () => HistoryType.chat,
          );
          
          // Parse MongoDB timestamp
          int ts = DateTime.now().millisecondsSinceEpoch;
          if (e['createdAt'] != null) {
            try {
              ts = DateTime.parse(e['createdAt'].toString()).millisecondsSinceEpoch;
            } catch (_) {}
          }

          return HistoryItem(
            id: e['_id']?.toString() ?? e['id']?.toString() ?? DateTime.now().microsecondsSinceEpoch.toString(),
            type: hType,
            title: e['title'] as String? ?? '',
            detail: e['detail'] as String? ?? '',
            timestampMs: ts,
            extra: (e['extra'] as Map?)?.cast<String, Object?>(),
          );
        }).toList();

        if (parsed.isNotEmpty) {
          final merged = <String, HistoryItem>{};
          // Pre-populate with cloud items (older cloud timestamp items get overwritten by local if overlap)
          for (final item in parsed) {
            merged[item.id] = item;
          }
          // Local items are typically newer
          for (final item in _items) {
            merged[item.id] = item;
          }
          _items = merged.values.toList()..sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
          await _persist();
        }
      } catch (err) {
        debugPrint('Cloud sync load failed: $err');
      }
    }
  }

  Future<void> add(HistoryItem item) async {
    _items.insert(0, item);
    await _persist();

    final syncEnabled = _prefs.getBool('syncToCloud') ?? false;
    if (syncEnabled) {
      try {
        await ApiClient().saveHistory({
          'type': item.type.name,
          'title': item.title,
          'detail': item.detail,
          'extra': item.extra,
        });
      } catch (err) {
        debugPrint('Cloud save failed: $err');
      }
    }
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => e.id == id);
    await _persist();
  }

  Future<void> clear() async {
    _items.clear();
    await _persist();
  }

  Future<void> _persist() async {
    await _prefs.setString(_key, HistoryItem.encodeList(_items));
    notifyListeners();
  }
}

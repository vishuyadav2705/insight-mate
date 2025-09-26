import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/history_item.dart';

class HistoryService extends ChangeNotifier {
  HistoryService(this._prefs);

  final SharedPreferences _prefs;
  static const String _key = 'history_items_v1';

  List<HistoryItem> _items = <HistoryItem>[];
  List<HistoryItem> get items => List.unmodifiable(_items);

  Future<void> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    _items = HistoryItem.decodeList(raw);
    notifyListeners();
  }

  Future<void> add(HistoryItem item) async {
    _items.insert(0, item);
    await _persist();
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



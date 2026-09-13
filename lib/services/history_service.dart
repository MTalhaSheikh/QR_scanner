import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

/// Simple singleton wrapper around SharedPreferences that persists the
/// user's scan + generate history as a JSON blob.
class HistoryService {
  HistoryService._internal();
  static final HistoryService instance = HistoryService._internal();

  static const _key = 'scancraft_history_v1';

  List<ScanRecord> _cache = [];
  bool _loaded = false;

  Future<List<ScanRecord>> load() async {
    if (_loaded) return _cache;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key) ?? '';
    _cache = ScanRecord.decodeList(raw)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    _loaded = true;
    return _cache;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, ScanRecord.encodeList(_cache));
  }

  Future<List<ScanRecord>> add(ScanRecord record) async {
    await load();
    _cache.insert(0, record);
    await _persist();
    return _cache;
  }

  Future<List<ScanRecord>> remove(String id) async {
    await load();
    _cache.removeWhere((r) => r.id == id);
    await _persist();
    return _cache;
  }

  Future<List<ScanRecord>> toggleFavorite(String id) async {
    await load();
    final idx = _cache.indexWhere((r) => r.id == id);
    if (idx != -1) {
      _cache[idx].favorite = !_cache[idx].favorite;
      await _persist();
    }
    return _cache;
  }

  Future<List<ScanRecord>> clearAll() async {
    _cache = [];
    await _persist();
    return _cache;
  }
}

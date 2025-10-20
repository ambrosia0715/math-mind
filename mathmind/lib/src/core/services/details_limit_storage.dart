import 'package:shared_preferences/shared_preferences.dart';

class DetailsLimitSnapshot {
  const DetailsLimitSnapshot({required this.detailsOpened, required this.date});

  final int detailsOpened;
  final DateTime date;
}

class DetailsLimitStorage {
  static const _countKey = 'details_limit_count';
  static const _dateKey = 'details_limit_date';

  Future<DetailsLimitSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_countKey);
    final dateIso = prefs.getString(_dateKey);
    if (count == null || dateIso == null) return null;
    final date = DateTime.tryParse(dateIso);
    if (date == null) return null;
    return DetailsLimitSnapshot(detailsOpened: count, date: date);
  }

  Future<void> save({required int detailsOpened, required DateTime date}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, detailsOpened);
    await prefs.setString(_dateKey, date.toIso8601String());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
    await prefs.remove(_dateKey);
  }
}

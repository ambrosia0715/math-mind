import 'package:shared_preferences/shared_preferences.dart';

class DailyLimitSnapshot {
  const DailyLimitSnapshot({required this.questionsAsked, required this.date});

  final int questionsAsked;
  final DateTime date;
}

class DailyLimitStorage {
  static const _countKey = 'daily_limit_questions';
  static const _dateKey = 'daily_limit_date';

  Future<DailyLimitSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_countKey);
    final dateIso = prefs.getString(_dateKey);
    if (count == null || dateIso == null) {
      return null;
    }
    final date = DateTime.tryParse(dateIso);
    if (date == null) {
      return null;
    }
    return DailyLimitSnapshot(questionsAsked: count, date: date);
  }

  Future<void> save({
    required int questionsAsked,
    required DateTime date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_countKey, questionsAsked);
    await prefs.setString(_dateKey, date.toIso8601String());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countKey);
    await prefs.remove(_dateKey);
  }
}

import '../../../core/services/lesson_history_service.dart';
import '../../lessons/domain/lesson_history.dart';

class RetentionService {
  RetentionService(this._historyService);

  final LessonHistoryService _historyService;

  Stream<List<LessonHistory>> watchDueReviews(String userId) {
    return _historyService.watchDueReviews(userId).map((lessons) {
      final now = DateTime.now();
      return lessons
          .where(
            (lesson) =>
                lesson.reviewDue != null && !lesson.reviewDue!.isAfter(now),
          )
          .toList();
    });
  }

  Future<void> markRetentionResult({
    required LessonHistory history,
    required int score,
  }) async {
    final updated = history.copyWith(retentionScore: score, reviewDue: null);
    await _historyService.save(updated);
  }
}

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/application/auth_provider.dart';
import '../../lessons/domain/lesson_history.dart';
import '../services/retention_service.dart';

class RetentionProvider extends ChangeNotifier {
  RetentionProvider({
    required AuthProvider authProvider,
    required RetentionService retentionService,
  }) : _authProvider = authProvider,
       _retentionService = retentionService {
    _authProvider.addListener(_handleAuthChange);
    _handleAuthChange();
  }

  final AuthProvider _authProvider;
  final RetentionService _retentionService;

  StreamSubscription<List<LessonHistory>>? _subscription;
  List<LessonHistory> _dueLessons = [];
  bool _loading = false;

  List<LessonHistory> get dueLessons => _dueLessons;
  bool get isLoading => _loading;

  // 진행 기준: 복습 화면을 통해 재평가된 점수(lastRetentionScore) >= 30
  int get progressedCount => _dueLessons.where((l) => (l.lastRetentionScore ?? -1) >= 30).length;
  int get pendingCount => (_dueLessons.length - progressedCount).clamp(0, _dueLessons.length);

  Future<void> markRetentionComplete(LessonHistory history, int score) async {
    await _retentionService.markRetentionResult(history: history, score: score);
  }

  void _handleAuthChange() {
    _subscription?.cancel();
    if (!_authProvider.isSignedIn) {
      _dueLessons = [];
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();

    _subscription = _retentionService
        .watchDueReviews(_authProvider.currentUser!.id)
        .listen((lessons) {
          _dueLessons = lessons;
          _loading = false;
          notifyListeners();
        });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _authProvider.removeListener(_handleAuthChange);
    super.dispose();
  }
}

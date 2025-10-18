import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/lesson_history_service.dart';
import '../../auth/application/auth_provider.dart';
import '../domain/lesson_history.dart';

enum LessonStage {
  idle,
  generatingContent,
  ready,
  awaitingEvaluation,
  evaluating,
  completed,
  error,
}

class LessonSessionProvider extends ChangeNotifier {
  LessonSessionProvider({
    required AuthProvider authProvider,
    required LessonHistoryService historyService,
    required AiContentService aiContentService,
  }) : _authProvider = authProvider,
       _historyService = historyService,
       _aiContentService = aiContentService;

  final AuthProvider _authProvider;
  final LessonHistoryService _historyService;
  final AiContentService _aiContentService;

  LessonStage _stage = LessonStage.idle;
  String? _topic;
  int _targetGrade = 1;
  String? _conceptExplanation;
  String? _aiFeedback;
  int? _initialScore;
  String? _detectedConcept;
  String? _errorMessage;

  LessonStage get stage => _stage;
  String? get topic => _topic;
  int get targetGrade => _targetGrade;
  String? get conceptExplanation => _conceptExplanation;
  String? get aiFeedback => _aiFeedback;
  int? get initialScore => _initialScore;
  String? get detectedConcept => _detectedConcept;
  String? get errorMessage => _errorMessage;

  bool get canStart =>
      _stage == LessonStage.idle || _stage == LessonStage.completed;
  bool get requiresEvaluation => _stage == LessonStage.awaitingEvaluation;

  Future<void> startLesson({
    required String topic,
    required int grade,
    required String learnerName,
  }) async {
    if (!canStart) return;

    _stage = LessonStage.generatingContent;
    _topic = topic;
    _targetGrade = grade;
    _conceptExplanation = null;
    _initialScore = null;
    _aiFeedback = null;
    _detectedConcept = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final explanation = await _aiContentService.explainConcept(
        topic: topic,
        grade: grade,
        learnerName: learnerName,
      );
      _conceptExplanation = explanation;
      _stage = LessonStage.ready;
    } catch (error, stackTrace) {
      debugPrint('Lesson generation failed: $error\n$stackTrace');
      _errorMessage =
          'Something went wrong while generating the content. Please try again.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  Future<void> analyzeProblem(String userProblem) async {
    if (_topic == null) return;
    try {
      final concept = await _aiContentService.detectConceptFromProblem(
        userProblem,
      );
      _detectedConcept = concept;
    } catch (error) {
      debugPrint('Problem analysis failed: $error');
    }
    notifyListeners();
  }

  Future<void> evaluateUnderstanding(String learnerExplanation) async {
    if (_topic == null || _conceptExplanation == null) return;

    _stage = LessonStage.evaluating;
    _aiFeedback = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final score = await _aiContentService.evaluateUnderstanding(
        topic: _topic!,
        expectedConcept: _conceptExplanation!,
        learnerExplanation: learnerExplanation,
      );
      _initialScore = score;
      _aiFeedback = _buildFeedback(score);
      _stage = LessonStage.awaitingEvaluation;
    } catch (error, stackTrace) {
      debugPrint('Evaluation failed: $error\n$stackTrace');
      _errorMessage =
          'We could not evaluate the explanation. Please try again in a moment.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  Future<void> commitLesson() async {
    if (_topic == null || _initialScore == null || !_authProvider.isSignedIn) {
      return;
    }

    try {
      final history = LessonHistory(
        id: const Uuid().v4(),
        userId: _authProvider.currentUser!.id,
        topic: _topic!,
        learnedAt: DateTime.now(),
        initialScore: _initialScore,
        reviewDue: DateTime.now().add(const Duration(days: 2)),
        retentionScore: null,
        detectedConcept: _detectedConcept,
      );

      await _historyService.save(history);
      _stage = LessonStage.completed;
    } catch (error, stackTrace) {
      debugPrint('Failed to save lesson history: $error\n$stackTrace');
      _errorMessage = 'We were unable to save your learning history.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  void reset() {
    _stage = LessonStage.idle;
    _topic = null;
    _conceptExplanation = null;
    _aiFeedback = null;
    _initialScore = null;
    _detectedConcept = null;
    _errorMessage = null;
    notifyListeners();
  }

  String _buildFeedback(int score) {
    if (score >= 85) {
      return 'Excellent work! You clearly understand the concept.';
    } else if (score >= 60) {
      return 'Nice job! A bit more practice will make it stick.';
    } else {
      return 'Let us revisit the explanation and walk through the example together.';
    }
  }
}

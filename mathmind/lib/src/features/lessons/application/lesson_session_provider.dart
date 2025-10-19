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
  int _targetAge = 6;
  String? _conceptExplanation;
  String? _aiFeedback;
  int? _initialScore;
  String? _detectedConcept;
  String? _errorMessage;
  List<ConceptBreakdown> _conceptBreakdown = [];
  ConceptBreakdown? _selectedConcept;
  bool _isAnalyzingConcepts = false;
  String? _pendingConceptProblem;

  LessonStage get stage => _stage;
  String? get topic => _topic;
  int get targetAge => _targetAge;
  String? get conceptExplanation => _conceptExplanation;
  String? get aiFeedback => _aiFeedback;
  int? get initialScore => _initialScore;
  String? get detectedConcept => _detectedConcept;
  String? get errorMessage => _errorMessage;
  bool get isAnalyzingConcepts => _isAnalyzingConcepts;
  ConceptBreakdown? get selectedConcept => _selectedConcept;
  List<ConceptBreakdown> get conceptBreakdown =>
      List.unmodifiable(_conceptBreakdown);

  bool get canStart =>
      _stage == LessonStage.idle || _stage == LessonStage.completed;
  bool get requiresEvaluation => _stage == LessonStage.awaitingEvaluation;

  Future<void> startLesson({
    required String topic,
    required int age,
    required String learnerName,
  }) async {
    if (!canStart) return;

    _stage = LessonStage.generatingContent;
    _topic = topic;
    _targetAge = age;
    _conceptExplanation = null;
    _initialScore = null;
    _aiFeedback = null;
    _detectedConcept = null;
    _errorMessage = null;
    _conceptBreakdown = [];
    _selectedConcept = null;
    _isAnalyzingConcepts = false;
    _pendingConceptProblem = null;
    notifyListeners();

    try {
      String? explanation;
      final user = _authProvider.currentUser;
      if (user != null) {
        final recentLesson = await _historyService.fetchLatestByTopic(
          userId: user.id,
          topic: topic,
        );
        final cachedExplanation = recentLesson?.conceptExplanation?.trim();
        if (cachedExplanation != null && cachedExplanation.isNotEmpty) {
          explanation = cachedExplanation;
        }
      }

      explanation ??= await _aiContentService.explainConcept(
        topic: topic,
        age: age,
        learnerName: learnerName,
      );
      _conceptExplanation = explanation;
      _stage = LessonStage.ready;
    } catch (error, stackTrace) {
      debugPrint('Lesson generation failed: $error\n$stackTrace');
      _errorMessage = '학습 내용을 생성하는 중 문제가 발생했어요. 다시 시도해 주세요.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  Future<void> analyzeProblem(String userProblem) async {
    if (_topic == null) return;

    final trimmed = userProblem.trim();
    if (trimmed.isEmpty) {
      clearConceptSuggestions();
      return;
    }

    _pendingConceptProblem = trimmed;
    _conceptBreakdown = [];
    _selectedConcept = null;
    _detectedConcept = null;
    _isAnalyzingConcepts = true;
    notifyListeners();

    try {
      final concepts = await _aiContentService.analyzeProblemConcepts(
        problem: trimmed,
        age: _targetAge,
      );
      if (_pendingConceptProblem != trimmed) {
        return;
      }
      _conceptBreakdown = concepts;
    } catch (error, stackTrace) {
      if (_pendingConceptProblem == trimmed) {
        debugPrint('Problem analysis failed: $error\n$stackTrace');
        _conceptBreakdown = [];
      }
    } finally {
      if (_pendingConceptProblem == trimmed) {
        _isAnalyzingConcepts = false;
        notifyListeners();
      }
    }
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
      _errorMessage = '설명을 평가할 수 없었어요. 잠시 후 다시 시도해 주세요.';
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
        reviewDue: DateTime.now().add(const Duration(minutes: 10)),
        retentionScore: null,
        detectedConcept: _detectedConcept,
        conceptExplanation: _conceptExplanation,
      );

      await _historyService.save(history);
      _stage = LessonStage.completed;
    } catch (error, stackTrace) {
      debugPrint('Failed to save lesson history: $error\n$stackTrace');
      _errorMessage = '학습 기록을 저장하지 못했어요.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  void reset() {
    _stage = LessonStage.idle;
    _topic = null;
    clearConceptSuggestions(notifyListenersNow: false);
    _conceptExplanation = null;
    _aiFeedback = null;
    _initialScore = null;
    _detectedConcept = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearConceptSuggestions({bool notifyListenersNow = true}) {
    _pendingConceptProblem = null;
    _conceptBreakdown = [];
    _selectedConcept = null;
    _isAnalyzingConcepts = false;
    _detectedConcept = null;
    if (notifyListenersNow) {
      notifyListeners();
    }
  }

  void selectConcept(ConceptBreakdown concept) {
    if (!_conceptBreakdown.contains(concept)) return;
    _selectedConcept = concept;
    _detectedConcept = concept.name;
    notifyListeners();
  }

  void deselectConcept() {
    if (_selectedConcept == null) return;
    _selectedConcept = null;
    _detectedConcept = null;
    notifyListeners();
  }

  String _buildFeedback(int score) {
    if (score >= 85) {
      return '정말 잘했어요! 개념을 확실히 이해했네요.';
    } else if (score >= 60) {
      return '잘하고 있어요! 조금만 더 연습하면 완전히 익힐 수 있어요.';
    } else {
      return '설명을 다시 살펴보고 함께 예제를 풀어봐요.';
    }
  }
}

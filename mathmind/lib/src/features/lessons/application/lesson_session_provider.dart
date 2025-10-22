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
  String? _learnerExplanation;
  String? _detailedExplanation;

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
  String? get learnerExplanation => _learnerExplanation;
  String? get detailedExplanation => _detailedExplanation;

  bool get canStart =>
      _stage == LessonStage.idle || _stage == LessonStage.completed;
  bool get requiresEvaluation => _stage == LessonStage.awaitingEvaluation;

  Future<void> startLesson({
    required String topic,
    required int difficulty,
    required String learnerName,
  }) async {
    // 진행 중인 생성/평가 단계에서는 시작 불가
    if (_stage == LessonStage.generatingContent ||
        _stage == LessonStage.evaluating) {
      return;
    }

    // 주제나 난이도가 바뀌었으면 무조건 새로 조회
    final topicChanged = _topic != topic;
    final difficultyChanged = _targetAge != difficulty;
    final shouldRegenerate =
        topicChanged || difficultyChanged || _conceptExplanation == null;

    if (!shouldRegenerate) {
      // 완전히 동일한 주제+난이도: 기존 결과 재사용
      notifyListeners();
      return;
    }

    _stage = LessonStage.generatingContent;
    _topic = topic;
    _targetAge = difficulty;
    _conceptExplanation = null;
    _initialScore = null;
    _aiFeedback = null;
    _detectedConcept = null;
    _errorMessage = null;
    _conceptBreakdown = [];
    _selectedConcept = null;
    _isAnalyzingConcepts = false;
    _pendingConceptProblem = null;
    _learnerExplanation = null;
    _detailedExplanation = null;
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
        final cachedKeywords = recentLesson?.conceptKeywords;
        if (cachedExplanation != null && cachedExplanation.isNotEmpty) {
          explanation = cachedExplanation;
        }
        if (cachedKeywords != null && cachedKeywords.isNotEmpty) {
          // 접근개념 키워드도 캐싱
          _conceptBreakdown = cachedKeywords
              .map((k) => ConceptBreakdown(name: k, summary: ''))
              .toList();
        }
      }

      // Build concept-only prompt for problem-like topics (exclude step-by-step solutions)
      final isProblemLike = RegExp(
        r'[=<>]|\\w|\d+|\?|구하시오|문제',
      ).hasMatch(topic.toLowerCase());
      final conceptOnlyTopic = isProblemLike
          ? '$topic (문제 풀이 단계는 제외하고, 필요한 개념 정리만 간단히 알려줘. 정의, 핵심 성질, 핵심 공식 중심으로 5~7문장 내로 요약하고, 단계별 풀이/정답 유도/증명은 포함하지 말아줘)'
          : '$topic (정의와 핵심 개념/공식 중심으로 간단히 요약해줘. 예시는 짧게 한 줄 정도만)';

      explanation ??= await _aiContentService.explainConcept(
        topic: conceptOnlyTopic,
        difficulty: difficulty,
        learnerName: learnerName,
      );
      _conceptExplanation = explanation;

      // 키워드가 없으면 개념 분석 수행
      if (_conceptBreakdown.isEmpty) {
        try {
          final concepts = await _aiContentService.analyzeProblemConcepts(
            problem: topic,
            difficulty: difficulty,
          );
          _conceptBreakdown = concepts;
        } catch (e) {
          debugPrint('Failed to analyze concepts: $e');
          // 실패해도 계속 진행
        }
      }

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
        difficulty: _targetAge,
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
      // 세분화된 평가 (개념 인식, 적용, 연결) 사용
      final evaluation = await _aiContentService.evaluateUnderstandingDetailed(
        topic: _topic!,
        expectedConcept:
            _detectedConcept ??
            (_conceptBreakdown.isNotEmpty ? _conceptBreakdown.first.name : ''),
        learnerExplanation: learnerExplanation,
        difficulty: _targetAge,
      );

      _initialScore = evaluation.score;
      _learnerExplanation = learnerExplanation;

      // 세부 피드백 생성
      _aiFeedback = _buildDetailedFeedback(
        evaluation.recall,
        evaluation.application,
        evaluation.integration,
        evaluation.feedback,
      );
      _stage = LessonStage.awaitingEvaluation;
    } catch (error, stackTrace) {
      debugPrint('Evaluation failed: $error\n$stackTrace');
      _errorMessage = '설명을 평가할 수 없었어요. 잠시 후 다시 시도해 주세요.';
      _stage = LessonStage.error;
    }

    notifyListeners();
  }

  String _buildDetailedFeedback(
    int recall,
    int application,
    int integration,
    String aiFeedback,
  ) {
    final parts = <String>[];

    // AI 피드백 우선 사용
    if (aiFeedback.trim().isNotEmpty) {
      parts.add(aiFeedback.trim());
    }

    // 세부 점수 표시
    parts.add('\n📊 세부 평가:');
    parts.add('• 개념 인식: $recall점 ${_ratingEmoji(recall)}');
    parts.add('• 개념 적용: $application점 ${_ratingEmoji(application)}');
    parts.add('• 개념 연결: $integration점 ${_ratingEmoji(integration)}');

    // 개선 포인트
    final weakest = [
      recall,
      application,
      integration,
    ].reduce((a, b) => a < b ? a : b);
    if (weakest == recall && recall < 70) {
      parts.add('\n💡 개선 포인트: 핵심 용어와 정의를 명확히 언급해 보세요.');
    } else if (weakest == application && application < 70) {
      parts.add('\n💡 개선 포인트: 문제 풀이 절차나 공식 사용법을 구체적으로 설명해 보세요.');
    } else if (weakest == integration && integration < 70) {
      parts.add('\n💡 개선 포인트: 개념 간 관계나 이유를 논리적으로 연결해 보세요.');
    }

    return parts.join('\n');
  }

  String _ratingEmoji(int score) {
    if (score >= 85) return '🌟';
    if (score >= 70) return '✅';
    if (score >= 50) return '⚠️';
    return '❌';
  }

  Future<void> commitLesson() async {
    if (_topic == null || !_authProvider.isSignedIn) {
      return;
    }

    try {
      // '더 자세히 보기'를 누르지 않은 경우 detailedExplanation을 null로 저장
      final shouldSaveDetailed =
          _detailedExplanation != null &&
          _detailedExplanation!.trim().isNotEmpty;

      // 키워드 목록 생성: breakdown에서 가져오거나, 주제 자체가 개념이면 주제를 키워드로 추가
      debugPrint(
        '💾 _conceptBreakdown: $_conceptBreakdown (length: ${_conceptBreakdown.length})',
      );

      final keywords = _conceptBreakdown
          .map((e) => e.name)
          .where((e) => e.trim().isNotEmpty)
          .toList();

      debugPrint('💾 Keywords from breakdown: $keywords');

      // 주제 자체가 개념(수식이나 문제가 아님)이라면 키워드에 추가
      final topicTrimmed = _topic!.trim();
      final isTopicAConcept = !_containsNumberOrOperator(topicTrimmed);
      if (isTopicAConcept && !keywords.contains(topicTrimmed)) {
        keywords.insert(0, topicTrimmed);
      }

      // breakdown이 비어있고 detectedConcept가 있으면 그것을 키워드로 사용
      if (keywords.isEmpty &&
          _detectedConcept != null &&
          _detectedConcept!.trim().isNotEmpty) {
        keywords.add(_detectedConcept!);
        debugPrint('💾 Using detectedConcept as keyword: $_detectedConcept');
      }

      // 그래도 비어있으면 주제에서 수학 키워드를 추출
      if (keywords.isEmpty) {
        final extractedKeywords = _extractConceptKeywordsFromText(topicTrimmed);
        keywords.addAll(extractedKeywords);
        debugPrint('💾 Extracted keywords from topic: $extractedKeywords');
      }

      debugPrint(
        '💾 Saving lesson - Topic: $topicTrimmed, Keywords: $keywords, IsTopicAConcept: $isTopicAConcept, Final keywords count: ${keywords.length}',
      );

      final history = LessonHistory(
        id: const Uuid().v4(),
        userId: _authProvider.currentUser!.id,
        topic: _topic!,
        learnedAt: DateTime.now(),
        initialScore: _initialScore,
        reviewDue: DateTime.now().add(const Duration(days: 3)),
        retentionScore: null,
        detectedConcept: _detectedConcept,
        conceptExplanation: _conceptExplanation,
        conceptKeywords: keywords.isEmpty ? null : keywords,
        learnerExplanation: _learnerExplanation,
        lastEvaluatedAt: _initialScore != null ? DateTime.now() : null,
        detailedExplanation: shouldSaveDetailed ? _detailedExplanation : null,
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

  bool _containsNumberOrOperator(String s) =>
      RegExp(r'[0-9+\-*/×÷=^()]').hasMatch(s);

  /// 주제 텍스트에서 수학 개념 키워드를 추출하는 헬퍼 메서드
  List<String> _extractConceptKeywordsFromText(String text) {
    final keywords = <String>[];
    final lowerText = text.toLowerCase();

    // 자주 사용되는 수학 개념 키워드 목록
    const conceptPatterns = [
      '함수',
      '미분',
      '적분',
      '극한',
      '도함수',
      '접선',
      '극값',
      '최댓값',
      '최솟값',
      '삼각함수',
      '지수함수',
      '로그함수',
      '이차함수',
      '다항함수',
      '벡터',
      '행렬',
      '기하',
      '확률',
      '통계',
      '수열',
      '급수',
      '부등식',
      '방정식',
      '등식',
      '증명',
      '그래프',
      '넓이',
      '부피',
      '길이',
      '속도',
      '가속도',
      '연속',
      '불연속',
      '수렴',
      '발산',
      '테일러',
      '롤',
    ];

    for (final pattern in conceptPatterns) {
      if (lowerText.contains(pattern) && !keywords.contains(pattern)) {
        keywords.add(pattern);
        if (keywords.length >= 3) break; // 최대 3개까지만
      }
    }

    return keywords;
  }

  void setDetailedExplanation(String text) {
    _detailedExplanation = text;
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
}

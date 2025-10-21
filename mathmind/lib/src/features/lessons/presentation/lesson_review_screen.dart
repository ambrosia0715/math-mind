import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/lesson_history_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../lessons/domain/lesson_history.dart';
import '../../../core/utils/math_text.dart';
import '../../../core/services/speech_service.dart';

class LessonReviewScreen extends StatefulWidget {
  const LessonReviewScreen({
    super.key,
    required this.lesson,
    this.startWithBlankExplanation = false,
  });

  static const routeName = '/lesson-review';

  final LessonHistory lesson;
  final bool startWithBlankExplanation;

  @override
  State<LessonReviewScreen> createState() => _LessonReviewScreenState();
}

class _LessonReviewScreenState extends State<LessonReviewScreen> {
  late LessonHistory _lesson;
  String? _explanation;
  TextEditingController? _learnerCtrl;
  bool _isRegenerating = false;
  String? _regenerateError;
  bool _savingEval = false;
  int? _evalScore;
  String? _evalFeedback;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _explanation = _lesson.conceptExplanation?.trim();
    final startBlank = widget.startWithBlankExplanation;
    final initialLearner = startBlank ? '' : (_lesson.learnerExplanation ?? '');
    _learnerCtrl = TextEditingController(text: initialLearner);
    if (_explanation == null || _explanation!.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_regenerateExplanation());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isReview = widget.startWithBlankExplanation;
    
    // 최근학습: 기존 점수 표시, 복습: 숨김
    final initialScore = _lesson.initialScore != null
        ? '${_lesson.initialScore}'
        : '-';
    final showScore = !isReview; // 복습 모드에서는 이전 점수 숨김

    return Scaffold(
      appBar: AppBar(
        title: Text(_lesson.topic),
        actions: [
          if (!isReview && _lesson.initialScore != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: '현재 이해도는 수정/재평가할 수 있어요',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('아래 설명란에 수정하고 "이해도 평가받기"를 눌러 점수를 갱신하세요.'),
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (showScore)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.reviewInitialScore(initialScore),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Chip(
                          label: Text('현재 점수: $initialScore'),
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '아래에서 설명을 수정하고 재평가하면 점수가 갱신돼요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          if (showScore) const SizedBox(height: 16),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.lessonExplanationTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (_isRegenerating)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const LinearProgressIndicator(),
                        const SizedBox(height: 12),
                        Text(
                          l10n.reviewRegenerating,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  else if (_explanation != null && _explanation!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((_lesson.conceptKeywords ?? []).isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final kw in (_lesson.conceptKeywords ?? []))
                                Chip(label: Text('# $kw')),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        SelectableText(
                          cleanMathForDisplay(_explanation!),
                          // 개념 설명 전체 표시
                          toolbarOptions: const ToolbarOptions(
                            copy: true,
                            selectAll: true,
                          ),
                          showCursor: false,
                        ),
                        if ((_lesson.detailedExplanation ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Divider(),
                          const SizedBox(height: 12),
                          Text(
                            '자세한 설명',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SelectableText(
                            cleanMathForDisplay(
                              _lesson.detailedExplanation!.trim(),
                            ),
                            // 풀이/예시/단계별 설명 전체 표시
                            toolbarOptions: const ToolbarOptions(
                              copy: true,
                              selectAll: true,
                            ),
                            showCursor: false,
                          ),
                        ],
                      ],
                    )
                  else ...[
                    Text(
                      _regenerateError ?? l10n.reviewMissingContent,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          unawaited(_regenerateExplanation());
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text(l10n.reviewRegenerateButton),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.lessonExplainBack,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  // 개념 중심 안내 문구
                  Text(
                    _buildConceptualPrompt(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _learnerCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.lessonYourExplanation,
                      hintText: '예: 함수는 입력값마다 하나의 출력값이 정해지는 대응 관계예요. 미분은 순간 변화율을 구하는 방법이에요.',
                    ),
                    minLines: 4,
                    maxLines: 8,
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _savingEval
                            ? null
                            : () async {
                                await _evaluateAndSave();
                              },
                        icon: const Icon(Icons.analytics_outlined),
                        label: Text(l10n.lessonEvaluateUnderstanding),
                      ),
                      OutlinedButton.icon(
                        onPressed: _listening
                            ? null
                            : () async {
                                final speech = context.read<SpeechService>();
                                _listening = true;
                                setState(() {});
                                final success = await speech.listen(
                                  onFinalResult: (text) {
                                    _learnerCtrl?.text = text;
                                    _listening = false;
                                    if (mounted) setState(() {});
                                  },
                                  onPartialResult: (text) {
                                    _learnerCtrl?.text = text;
                                  },
                                );
                                if (!success) {
                                  _listening = false;
                                  if (mounted) setState(() {});
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          l10n.lessonVoiceUnavailable,
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                        label: Text(
                          _listening
                              ? l10n.lessonListening
                              : l10n.lessonSpeakExplanation,
                        ),
                      ),
                    ],
                  ),
                  if (_savingEval) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_evalScore != null || _evalFeedback != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            context.l10n.lessonUnderstandingLabel(
                              (_evalScore ?? _lesson.initialScore ?? 0)
                                  .toString(),
                            ),
                          ),
                          avatar: const Icon(Icons.assessment_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_evalFeedback != null)
                      Text(cleanMathForDisplay(_evalFeedback!)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _regenerateExplanation() async {
    if (_isRegenerating) return;
    setState(() {
      _isRegenerating = true;
      _regenerateError = null;
    });
    final l10n = context.l10n;
    try {
      final aiService = context.read<AiContentService>();
      final historyService = context.read<LessonHistoryService>();
      final auth = context.read<AuthProvider>();
      final learnerName =
          auth.currentUser?.displayName ?? l10n.generalLearnerFallback;

      final explanation = await aiService.explainConcept(
        topic: _lesson.topic,
        difficulty: 5,
        learnerName: learnerName,
      );
      final trimmed = explanation.trim();
      final updated = _lesson.copyWith(
        conceptExplanation: trimmed.isEmpty ? null : trimmed,
      );
      await historyService.save(updated);
      if (!mounted) return;
      setState(() {
        _lesson = updated;
        _explanation = updated.conceptExplanation?.trim();
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to regenerate explanation: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _regenerateError = l10n.reviewRegenerateError;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRegenerating = false;
        });
      }
    }
  }

  String _buildConceptualPrompt() {
    final topic = _lesson.topic.toLowerCase();
    final keywords = _lesson.conceptKeywords ?? [];
    
    // 주제/키워드 기반 개념 중심 질문 생성
    if (topic.contains('함수') || keywords.any((k) => k.contains('함수'))) {
      return '💡 함수란 무엇이고, 어떤 성질을 가지고 있나요?';
    }
    if (topic.contains('미분') || keywords.any((k) => k.contains('미분'))) {
      return '💡 미분은 무엇을 의미하고, 어디에 사용되나요?';
    }
    if (topic.contains('적분') || keywords.any((k) => k.contains('적분'))) {
      return '💡 적분의 기본 개념과 넓이와의 관계를 설명해 주세요.';
    }
    if (topic.contains('수열') || keywords.any((k) => k.contains('수열'))) {
      return '💡 수열의 정의와 등차/등비수열의 차이를 설명해 주세요.';
    }
    if (topic.contains('확률') || keywords.any((k) => k.contains('확률'))) {
      return '💡 확률이란 무엇이고, 어떻게 계산하나요?';
    }
    if (topic.contains('방정식') || keywords.any((k) => k.contains('방정식'))) {
      return '💡 방정식이란 무엇이고, 어떻게 풀어야 하나요?';
    }
    if (topic.contains('그래프') || keywords.any((k) => k.contains('그래프'))) {
      return '💡 그래프의 의미와 좌표 개념을 설명해 주세요.';
    }
    
    // 일반 fallback
    return '💡 이 개념의 핵심 정의와 성질, 활용 방법을 설명해 주세요.';
  }

  @override
  void dispose() {
    _learnerCtrl?.dispose();
    super.dispose();
  }

  Future<void> _evaluateAndSave() async {
    if (_savingEval) return;
    setState(() {
      _savingEval = true;
      _evalFeedback = null;
    });
    try {
      final ai = context.read<AiContentService>();
      final historyService = context.read<LessonHistoryService>();
      final explanation = (_learnerCtrl?.text ?? '').trim();
      
      // 세분화된 평가 (개념 인식, 적용, 연결) 사용
      final evaluation = await ai.evaluateUnderstandingDetailed(
        topic: _lesson.topic,
        expectedConcept:
            _lesson.detectedConcept ??
            ((_lesson.conceptKeywords ?? []).isNotEmpty
                ? (_lesson.conceptKeywords!.first)
                : ''),
        learnerExplanation: explanation,
        difficulty: _lesson.initialScore != null 
            ? ((_lesson.initialScore! / 10).round().clamp(0, 9))
            : null,
      );
      
      final score = evaluation.score;
      final feedback = _buildDetailedFeedback(
        evaluation.recall,
        evaluation.application,
        evaluation.integration,
        evaluation.feedback,
      );
      
      // 복습 경로(startWithBlankExplanation == true)에서는 lastRetentionScore로 저장하여 진행 여부 판단
      final updated = widget.startWithBlankExplanation
          ? _lesson.copyWith(
              lastRetentionScore: score,
              lastRetentionEvaluatedAt: DateTime.now(),
              learnerExplanation: explanation,
            )
          : _lesson.copyWith(
              initialScore: score,
              learnerExplanation: explanation,
              lastEvaluatedAt: DateTime.now(),
            );
      await historyService.save(updated);
      if (!mounted) return;
      setState(() {
        _lesson = updated;
        _evalScore = score;
        _evalFeedback = feedback;
      });
    } catch (error, stackTrace) {
      debugPrint('Evaluation failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _evalFeedback = '평가 중 오류가 발생했어요. 다시 시도해 주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _savingEval = false);
    }
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
    final weakest = [recall, application, integration].reduce((a, b) => a < b ? a : b);
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
}

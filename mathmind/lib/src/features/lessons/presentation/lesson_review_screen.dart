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
  const LessonReviewScreen({super.key, required this.lesson, this.startWithBlankExplanation = false});

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
    final initialScore = _lesson.initialScore != null
        ? '${_lesson.initialScore}'
        : '-';
  // Retention score removed; we only show initial understanding score

    return Scaffold(
      appBar: AppBar(title: Text(_lesson.topic)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reviewInitialScore(initialScore),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
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
                        SelectableText(cleanMathForDisplay(_explanation!)),
                        if ((_lesson.detailedExplanation ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Divider(),
                          const SizedBox(height: 12),
                          Text('자세한 설명', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 8),
                          SelectableText(cleanMathForDisplay(_lesson.detailedExplanation!.trim())),
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
                  Text(l10n.lessonExplainBack, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _learnerCtrl,
                    decoration: InputDecoration(labelText: l10n.lessonYourExplanation),
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
                                      SnackBar(content: Text(l10n.lessonVoiceUnavailable)),
                                    );
                                  }
                                }
                              },
                        icon: Icon(_listening ? Icons.mic_off : Icons.mic),
                        label: Text(_listening ? l10n.lessonListening : l10n.lessonSpeakExplanation),
                      ),
                    ],
                  ),
                  if (_savingEval) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (_evalScore != null || _evalFeedback != null) ...[
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      Chip(label: Text(context.l10n.lessonUnderstandingLabel((_evalScore ?? _lesson.initialScore ?? 0).toString())), avatar: const Icon(Icons.assessment_outlined)),
                    ]),
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
      int score;
      try {
        score = await ai.evaluateUnderstanding(
          topic: _lesson.topic,
          expectedConcept: _lesson.detectedConcept ?? ((_lesson.conceptKeywords ?? []).isNotEmpty ? (_lesson.conceptKeywords!.first) : ''),
          learnerExplanation: explanation,
        );
      } catch (_) {
        score = ai.heuristicScoreConceptual(explanation, topic: _lesson.topic, expectedConcept: _lesson.detectedConcept);
      }
      final feedback = _buildFeedback(score);
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
    } finally {
      if (mounted) setState(() => _savingEval = false);
    }
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

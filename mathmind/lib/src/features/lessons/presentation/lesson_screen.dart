// Replacing file content with a minimal stub to resolve mid-file duplication.
// The full, clean implementation will be re-added next.
import 'package:flutter/material.dart';

class LessonScreen extends StatelessWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Lesson screen loading...')),
    );
  }
}
const _legacy = r'''
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/services/ai_content_service.dart';
import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';

// Using real app services and localization; strings come from app_localizations via context.l10n.

// ---- Helpers: math text cleaning and keyword utilities ----
String _cleanTextForDisplay(String text) {
  var cleaned = text;
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\((.*?)\\\)'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$(.*?)\$'), (m) => m.group(1) ?? '');
  cleaned = cleaned
      .replaceAll(r'\\times', '×')
      .replaceAll(r'\\div', '÷')
      .replaceAll(r'\\pm', '±')
      .replaceAll(r'\\le', '≤')
      .replaceAll(r'\\ge', '≥')
      .replaceAll(r'\\ne', '≠')
      .replaceAll(r'\\approx', '≈')
      .replaceAll(r'\\pi', 'π')
      .replaceAll(r'\\alpha', 'α')
      .replaceAll(r'\\beta', 'β')
      .replaceAll(r'\\theta', 'θ')
      .replaceAll(r'\\sqrt', '√');
  const fractions = {
    '1/2': '½',
    '1/3': '⅓',
    '2/3': '⅔',
    '1/4': '¼',
    '3/4': '¾',
    '1/5': '⅕',
    '2/5': '⅖',
    '3/5': '⅗',
    '4/5': '⅘',
    '1/6': '⅙',
    '5/6': '⅚',
    '1/8': '⅛',
    '3/8': '⅜',
    '5/8': '⅝',
    '7/8': '⅞',
  };
  fractions.forEach((k, v) => cleaned = cleaned.replaceAll(k, v));
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\frac\s*\{([^}]*)\}\s*\{([^}]*)\}'),
    (m) {
      final n = (m.group(1) ?? '').trim();
      final d = (m.group(2) ?? '').trim();
      final key = '$n/$d';
      return fractions[key] ?? '($n)/($d)';
    },
  );
  cleaned = cleaned.replaceAll('**', '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^}]*)\}'), (m) {
    final c = (m.group(1) ?? '').trim();
    return c.contains(RegExp(r'[+\-*/]')) ? '√($c)' : '√$c';
  });
  cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
  cleaned = cleaned.replaceAll('\\', '');
  cleaned = cleaned.replaceAll('{', '').replaceAll('}', '');
  return cleaned.trim();
}

const List<String> _knownConceptKeywords = [
  '함수', '삼각함수', '지수함수', '로그함수', '그래프', '좌표', '기울기', '절편', '꼭짓점',
  '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율',
  '도형', '기하', '삼각형', '사각형', '원', '원의 넓이', '둘레', '피타고라스', '벡터', '행렬',
  '미분', '적분', '극한',
  '확률', '통계', '평균', '중앙값', '최빈값', '표준편차',
  '사인', '코사인', '탄젠트',
  '로그', '지수', '집합',
  'fraction', 'decimal', 'integer', 'rational', 'irrational', 'ratio', 'proportion', 'percent', 'percentage',
  'probability', 'statistics', 'mean', 'median', 'mode', 'equation', 'inequality', 'quadratic', 'polynomial',
  'function', 'graph', 'coordinate', 'slope', 'intercept', 'vertex', 'maximum', 'minimum', 'geometry',
  'triangle', 'rectangle', 'square', 'circle', 'angle', 'sine', 'cosine', 'tangent', 'area', 'perimeter',
  'volume', 'surface area', 'pythagorean', 'sequence', 'series', 'arithmetic', 'geometric', 'matrix', 'vector',
  'set', 'derivative', 'integral', 'limit', 'log', 'exponential',
];

bool _containsNumberOrOperator(String s) => RegExp(r'[0-9+\-*/×÷=^]').hasMatch(s);

bool _isGenericConceptQuery(String? topic) {
  class _VisualAidPlan {
    const _VisualAidPlan({required this.needsImage, required this.focus});
    final bool needsImage;
    final String focus;
  }
              },
            ),
          const SizedBox(height: 16),
          if (session.conceptExplanation != null)
            _buildEvaluationCard(context, session),
          const SizedBox(height: 16),
          if (session.aiFeedback != null)
            _FeedbackCard(
              score: session.initialScore,
              feedback: session.aiFeedback!,
            ),
          if (session.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                session.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          if (session.requiresEvaluation)
            FilledButton(
              onPressed: () async {
                await session.commitLesson();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.lessonSaveAndReturn),
            ),
        ],
      ),
    );
  }

  // topic card
  Widget _buildTopicCard(BuildContext context, LessonSessionProvider session) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lessonTellWhatToLearn, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(labelText: l10n.lessonTopicLabel, hintText: l10n.lessonTopicHint),
              onChanged: (value) => _handlePromptChanged(value, session),
            ),
            if (session.isAnalyzingConcepts)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if (!session.isAnalyzingConcepts && session.conceptBreakdown.isNotEmpty)
              _buildConceptHelper(context, session),
            const SizedBox(height: 12),
            Row(children: [
              const Text('난이도:'),
              Expanded(
                child: Slider(
                  value: _selectedDifficulty.toDouble(),
                  min: 0,
                  max: 9,
                  divisions: 9,
                  class _VisualAidPlan {
                    const _VisualAidPlan({required this.needsImage, required this.focus});
                    final bool needsImage;
                    final String focus;
                  }
        )
        .toList();
    final explanation = session.selectedConcept?.summary.trim().isNotEmpty == true
        ? session.selectedConcept!.summary.trim()
        : l10n.lessonConceptNoSelection;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(l10n.lessonConceptHelperTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.lessonConceptHelperHint, style: theme.textTheme.bodySmall),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: conceptChips),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.lessonConceptExplanationTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Text(explanation, style: theme.textTheme.bodyMedium),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEvaluationCard(BuildContext context, LessonSessionProvider session) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(l10n.lessonExplainBack, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Builder(builder: (ctx) {
            final concepts = _findRelatedConceptKeywords(session);
            if (concepts.isEmpty) return const SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('아래 개념(들)을 직접 설명해 주세요:', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [for (final kw in concepts) Chip(label: Text(kw))]),
              const SizedBox(height: 12),
            ]);
          }),
          TextField(
            controller: _explanationController,
            decoration: InputDecoration(labelText: l10n.lessonYourExplanation, hintText: '예시: 함수란 무엇인지, 미분이 어떤 의미인지 직접 설명해 주세요.'),
            minLines: 4,
            maxLines: 8,
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            FilledButton.icon(
              onPressed: stage == LessonStage.evaluating
                  ? null
                  : () async {
                      final explanation = _explanationController.text.trim();
                      if (explanation.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.lessonShareExplanationFirst)),
                        );
                        return;
                      }
                      await session.evaluateUnderstanding(explanation);
                    },
              icon: const Icon(Icons.analytics_outlined),
              label: Text(l10n.lessonEvaluateUnderstanding),
            ),
            OutlinedButton.icon(
              onPressed: _isListening
                  ? null
                  : () async {
                      setState(() => _isListening = true);
                      final success = await speech.listen(
                        onFinalResult: (text) {
                          _explanationController.text = text;
                          setState(() => _isListening = false);
                        },
                        onPartialResult: (text) {
                          _explanationController.text = text;
                        },
                      );
                      if (!success) {
                        setState(() => _isListening = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.lessonVoiceUnavailable)),
                          );
                        }
                      }
                    },
              icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
              label: Text(_isListening ? l10n.lessonListening : l10n.lessonSpeakExplanation),
            ),
          ]),
          if (session.stage == LessonStage.evaluating)
            const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
        ]),
      ),
    );
  }

  // keyword preview + start
  Future<void> _showKeywordPreviewAndMaybeStart(
    BuildContext context,
    LessonSessionProvider session,
    String keyword,
  ) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('선택한 개념', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text('# $keyword', style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text(l10n.generalClose),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          if (ctx.mounted) Navigator.of(ctx).pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('"$keyword" 주제로 새 수업을 시작해요.')),
                          );
                          _topicController.text = keyword;
                          await _startLessonWithTopic(context, session, keyword);
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('이 개념으로 새 수업 시작'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetGeneratedContent(LessonSessionProvider session) {
    if (_isListening) setState(() => _isListening = false);
    final disallow = {LessonStage.generatingContent, LessonStage.evaluating};
    if (disallow.contains(session.stage)) return;
    final hasGenerated = session.conceptExplanation != null ||
        session.aiFeedback != null ||
        session.requiresEvaluation ||
        session.stage == LessonStage.ready ||
        session.stage == LessonStage.awaitingEvaluation ||
        session.stage == LessonStage.completed;
    final hasUserExplanation = _explanationController.text.isNotEmpty;
    if (!hasGenerated && !hasUserExplanation) return;
    session.reset();
    _explanationController.clear();
    setState(_resetVisualState);
  }

  void _resetVisualState() {
    _visualCacheKey = null;
    _visualDescription = null;
    _visualFocusHint = null;
    _isVisualLoading = false;
    _visualImageTask = null;
    _visualImage = null;
  }

  void _handlePromptChanged(String value, LessonSessionProvider session) {
    _resetGeneratedContent(session);
    final trimmed = value.trim();
    if (trimmed.length >= 6) {
      session.analyzeProblem(trimmed);
    } else if (session.conceptBreakdown.isNotEmpty || session.isAnalyzingConcepts) {
      session.clearConceptSuggestions();
    }
  }

  Future<void> _startLessonWithTopic(
    BuildContext context,
    LessonSessionProvider session,
    String topic,
  ) async {
    if (session.stage == LessonStage.generatingContent || session.stage == LessonStage.evaluating) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reviewRegenerating)),
        );
      }
      return;
    }

    final trimmedTopic = topic.trim();
    final l10n = context.l10n;
    if (trimmedTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonEnterTopicFirst)),
      );
      return;
    }

    final subscription = context.read<SubscriptionProvider>();
    if (!subscription.canAskNewQuestion()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.lessonDailyLimitReached)),
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();

    await session.startLesson(
      topic: trimmedTopic,
      difficulty: _selectedDifficulty,
      learnerName: auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    subscription.registerQuestionAsked();
    session.clearConceptSuggestions();
    _topicController.text = trimmedTopic;
    if (!mounted) return;
    setState(_resetVisualState);
  }

  // Visual explanation flow
  _VisualAidPlan _buildVisualAidPlan(LessonSessionProvider session) {
    final topic = (session.topic ?? '').trim();
    final explanation = (session.conceptExplanation ?? '').trim();
    final raw = '$topic\n$explanation';
    final lower = raw.toLowerCase();
    final baseConcept = (session.selectedConcept?.name ?? session.detectedConcept ?? topic).trim();
    final fallbackFocus = baseConcept.isNotEmpty
        ? '$baseConcept을 떠올릴 수 있는 간단한 그림을 제안해 주세요.'
        : '핵심 개념을 떠올릴 수 있는 간단한 그림을 제안해 주세요.';
    bool hasAny(Iterable<String> words) => words.any((w) => w.isNotEmpty && lower.contains(w));
    if (hasAny(['graph','coordinate','function','equation','linear','quadratic','plot','slope','그래프','좌표','함수','방정식'])) {
      return const _VisualAidPlan(needsImage: true, focus: '그래프, 좌표, 함수 등 시각적 개념을 설명하는 그림을 제안해 주세요.');
    }
    if (hasAny(['difference','subtract','빼셈','빼기']) || raw.contains('-')) {
      return const _VisualAidPlan(needsImage: true, focus: '모둠에서 물건을 빼는 장면을 그려 남은 양이 분명하게 보이도록 해 주세요.');
    }
    if (hasAny(['multiplication','times','array','곱셈','곱하기','배수'])) {
      return const _VisualAidPlan(needsImage: true, focus: '배열(격자)을 사용해 곱셈을 설명하고, 행과 열에 라벨을 달아 주세요.');
    }
    if (hasAny(['area','shape','circle','rectangle','square','perimeter','면적','넓이','도형','사각형','원','반지름'])) {
      return const _VisualAidPlan(needsImage: true, focus: '관련 도형을 그리고 길이·각도·넓이 등을 표시하여 개념을 설명해 주세요.');
    }
    if (hasAny(['ratio','percent','probability','statistics','비율','백분율','확률','통계']) || raw.contains('%')) {
      return const _VisualAidPlan(needsImage: true, focus: '막대그래프 또는 파이차트로 비율을 명확하게 비교해 주세요.');
    }
    if (hasAny(['number line','timeline','수직선','시간'])) {
      return const _VisualAidPlan(needsImage: true, focus: '눈금이 있는 수직선을 그리고 설명에 사용된 주요 지점을 강조해 주세요.');
    }
    return _VisualAidPlan(needsImage: false, focus: fallbackFocus);
  }

  Future<void> _handleVisualExplanation(BuildContext context, LessonSessionProvider session) async {
    if (_isVisualLoading) return;
    final topic = session.topic;
    final explanation = session.conceptExplanation;
    if (topic == null || explanation == null) return;
    final plan = _buildVisualAidPlan(session);
    final focus = plan.focus;
    final cacheKey = '$topic|$focus|${session.targetAge}';
    if (_visualCacheKey == cacheKey && _visualDescription != null) {
      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
      return;
    }
    final aiService = context.read<AiContentService>();
    final learnerName = context.read<AuthProvider>().currentUser?.displayName ?? context.l10n.generalLearnerFallback;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isVisualLoading = true);
    try {
      final result = await aiService.createVisualExplanation(
        topic: topic,
        difficulty: session.targetAge,
        learnerName: learnerName,
        requestImage: plan.needsImage,
        imageFocus: focus,
        baseExplanation: explanation,
      );
      if (!mounted) return;
      setState(() {
        _visualCacheKey = cacheKey;
        _visualDescription = result.description;
        _visualFocusHint = focus;
        _visualImageTask = result.imageTask;
        _visualImage = (result.imageBytes != null || result.imageUrl != null)
            ? VisualExplanationImage(imageBytes: result.imageBytes, imageUrl: result.imageUrl)
            : null;
      });
      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
    } catch (error, stackTrace) {
      debugPrint('Visual explanation failed: $error\n$stackTrace');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.visualExplanationError)));
    } finally {
      if (mounted) setState(() => _isVisualLoading = false);
    }
  }

  Future<void> _presentVisualExplanationSheet(
    BuildContext context,
    LessonSessionProvider session,
    String focus,
  ) async {
    final description = _visualDescription;
    final topic = session.topic;
    if (description == null || topic == null || !context.mounted) return;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolvedFocus = focus.trim().isNotEmpty
        ? focus.trim()
        : (_visualFocusHint?.trim() ?? session.selectedConcept?.name ?? session.topic ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool isSpeaking = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final speechService = context.read<SpeechService>();
            speechService.setCompletionHandler(() {
              if (ctx.mounted) setSheetState(() => isSpeaking = false);
            });
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.visualExplanationTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (isSpeaking) {
                                await speechService.stopSpeaking();
                                setSheetState(() => isSpeaking = false);
                              } else {
                                setSheetState(() => isSpeaking = true);
                                await speechService.speakWithAgeAppropriateVoice(
                                  description,
                                  session.targetAge,
                                );
                              }
                            },
                            icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up_outlined),
                            tooltip: isSpeaking ? l10n.lessonStopSpeaking : l10n.lessonListen,
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (resolvedFocus.isNotEmpty) ...[
                        Text(
                          _cleanTextForDisplay(l10n.visualExplanationFocus(resolvedFocus)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!_isGenericConceptQuery(topic))
                        Builder(
                          builder: (context) {
                            final keywords = _findRelatedConceptKeywords(session);
                            if (keywords.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이 문제를 풀기 전에 알아두면 좋은 개념',
                                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final kw in keywords)
                                      ActionChip(
                                        label: Text('# $kw'),
                                        onPressed: () async {
                                          await speechService.stopSpeaking();
                                          speechService.setCompletionHandler(null);
                                          if (sheetContext.mounted) {
                                            Navigator.of(sheetContext).pop();
                                          }
                                          if (context.mounted) {
                                            await _showKeywordPreviewAndMaybeStart(context, session, kw);
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      Text(_cleanTextForDisplay(description), style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      if (_visualImage != null || _visualImageTask != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildVisualImageWidget(theme),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            speechService.stopSpeaking();
                            speechService.setCompletionHandler(null);
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.close),
                          label: Text(l10n.generalClose),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVisualImageWidget(ThemeData theme) {
    if (_visualImage != null) {
      final img = _visualImage!;
      if (img.imageBytes != null) {
        return Image.memory(img.imageBytes!, fit: BoxFit.cover);
      }
      if (img.imageUrl != null) {
        return Image.network(
          img.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1)
                : null;
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(value: value)),
            );
          },
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        );
      }
    }
    if (_visualImageTask != null) {
      return FutureBuilder<VisualExplanationImage?>(
        future: _visualImageTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.data;
          if (result == null) return const SizedBox.shrink();
          _visualImage = result;
          if (result.imageBytes != null) {
            return Image.memory(result.imageBytes!, fit: BoxFit.cover);
          }
          if (result.imageUrl != null) {
            return Image.network(
              result.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }
    return const SizedBox.shrink();
  }

  bool _looksLikeMathTopic(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    final hasNumber = RegExp(r'[0-9]').hasMatch(t);
    final hasOp = RegExp(r'[+\-*/×÷^=(){}\[\]]').hasMatch(t);
    if (hasNumber && hasOp) return true;
    const keywords = [
      '분수','소수','정수','자연수','유리수','무리수','비율','비례','백분율','확률','통계','평균','중앙값','최빈값','편차','표준편차',
      '방정식','연립방정식','이차방정식','부등식','식','항','항등식','함수','그래프','좌표','기울기','절편','꼭짓점','최대값','최소값',
      '도형','기하','삼각형','사각형','원','원의','각도','사인','코사인','탄젠트','넓이','둘레','부피','표면적','피타고라스',
      '수열','등차','등비','수열의 합','행렬','벡터','집합','확장','미분','적분','극한','로그','지수','다항식',
      '더하기','덧셈','빼기','뺄셈','곱하기','곱셈','나누기','나눗셈',
      'fraction','decimal','integer','rational','irrational','ratio','proportion','percent','percentage',
      'probability','statistics','mean','median','mode','equation','inequality','quadratic','polynomial','function','graph','coordinate','slope','intercept',
      'vertex','maximum','minimum','geometry','triangle','rectangle','square','circle','angle','sine','cosine','tangent','area','perimeter','volume','surface area','pythagorean',
      'sequence','series','arithmetic','geometric','matrix','vector','set','derivative','integral','limit','log','exponential',
    ];
    for (final kw in keywords) {
      if (kw.isEmpty) continue;
      final kwLower = kw.toLowerCase();
      if (t.contains(kwLower) || t.contains(kw)) return true;
    }
    return false;
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.content,
    required this.onVisualPressed,
    required this.isVisualLoading,
    required this.onKeywordTap,
  });

  final String content;
  final VoidCallback? onVisualPressed;
  final bool isVisualLoading;
  final void Function(String keyword) onKeywordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lessonExplanationTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final session = ctx.read<LessonSessionProvider>();
                if (_isGenericConceptQuery(session.topic)) return const SizedBox.shrink();
                final keywords = _findRelatedConceptKeywords(session);
                if (keywords.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관련 개념으로 다시 배워 보기', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final kw in keywords)
                        ActionChip(label: Text('# $kw'), onPressed: () => onKeywordTap(kw)),
                    ]),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Text(_cleanTextForDisplay(content)),
            if (onVisualPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isVisualLoading ? null : onVisualPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(isVisualLoading ? l10n.visualExplanationLoading : l10n.lessonShowMoreDetail),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.score, required this.feedback});

  final int? score;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scoreLabel = score?.toString() ?? '-';
    final chips = <Widget>[
      Chip(label: Text(l10n.lessonUnderstandingLabel(scoreLabel)), avatar: const Icon(Icons.assessment_outlined)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: chips),
            const SizedBox(height: 12),
            Text(_cleanTextForDisplay(feedback)),
          ],
        ),
      ),
    );
  }
}

class _VisualAidPlan {
  const _VisualAidPlan({required this.needsImage, required this.focus});
  final bool needsImage;
  final String focus;
}

// Single, clean implementation of LessonScreen and helpers. This fully replaces previous corrupted content.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';

// ---- Helpers: math text cleaning and keyword utilities ----
String _cleanTextForDisplay(String text) {
  var cleaned = text;
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\((.*?)\\\)'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$(.*?)\$'), (m) => m.group(1) ?? '');
  cleaned = cleaned
      .replaceAll(r'\times', '×')
      .replaceAll(r'\div', '÷')
      .replaceAll(r'\pm', '±')
      .replaceAll(r'\le', '≤')
      .replaceAll(r'\ge', '≥')
      .replaceAll(r'\ne', '≠')
      .replaceAll(r'\approx', '≈')
      .replaceAll(r'\pi', 'π')
      .replaceAll(r'\alpha', 'α')
      .replaceAll(r'\beta', 'β')
      .replaceAll(r'\theta', 'θ')
      .replaceAll(r'\sqrt', '√');
  const fractions = {
    '1/2': '½','1/3': '⅓','2/3': '⅔','1/4': '¼','3/4': '¾','1/5': '⅕','2/5': '⅖','3/5': '⅗','4/5': '⅘','1/6': '⅙','5/6': '⅚','1/8': '⅛','3/8': '⅜','5/8': '⅝','7/8': '⅞',
  };
  fractions.forEach((k, v) => cleaned = cleaned.replaceAll(k, v));
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\frac\s*\{([^}]*)\}\s*\{([^}]*)\}'), (m) {
    final n = (m.group(1) ?? '').trim();
    final d = (m.group(2) ?? '').trim();
    final key = '$n/$d';
    return fractions[key] ?? '($n)/($d)';
  });
  cleaned = cleaned.replaceAll('**', '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^}]*)\}'), (m) {
    final c = (m.group(1) ?? '').trim();
    return c.contains(RegExp(r'[+\-*/]')) ? '√($c)' : '√$c';
  });
  cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
  cleaned = cleaned.replaceAll('\\', '');
  cleaned = cleaned.replaceAll('{', '').replaceAll('}', '');
  return cleaned.trim();
}

const List<String> _knownConceptKeywords = [
  '함수','삼각함수','지수함수','로그함수','그래프','좌표','기울기','절편','꼭짓점',
  '분수','소수','정수','자연수','유리수','무리수','비율','비례','백분율',
  '도형','기하','삼각형','사각형','원','원의 넓이','둘레','피타고라스','벡터','행렬',
  '미분','적분','극한',
  '확률','통계','평균','중앙값','최빈값','표준편차',
  '사인','코사인','탄젠트',
  '로그','지수','집합',
  'fraction','decimal','integer','rational','irrational','ratio','proportion','percent','percentage',
  'probability','statistics','mean','median','mode','equation','inequality','quadratic','polynomial',
  'function','graph','coordinate','slope','intercept','vertex','maximum','minimum','geometry',
  'triangle','rectangle','square','circle','angle','sine','cosine','tangent','area','perimeter',
  'volume','surface area','pythagorean','sequence','series','arithmetic','geometric','matrix','vector',
  'set','derivative','integral','limit','log','exponential',
];

bool _containsNumberOrOperator(String s) => RegExp(r'[0-9+\-*/×÷=^]').hasMatch(s);

bool _isGenericConceptQuery(String? topic) {
  final t = (topic ?? '').trim();
  if (t.isEmpty) return false;
  if (_containsNumberOrOperator(t)) return false;
  if (_knownConceptKeywords.contains(t)) return true;
  if (t.length <= 6 && _knownConceptKeywords.any((k) => t == k || k.contains(t))) return true;
  return false;
}

class _VisualAidPlan {
  const _VisualAidPlan({required this.needsImage, required this.focus});
  final bool needsImage;
  final String focus;
}

class _ExplanationCard extends StatelessWidget {

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.content,
    required this.onVisualPressed,
    required this.isVisualLoading,
    required this.onKeywordTap,
  });

  final String content;
  final VoidCallback? onVisualPressed;
  final bool isVisualLoading;
  final void Function(String keyword) onKeywordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lessonExplanationTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final session = ctx.read<LessonSessionProvider>();
                if (_isGenericConceptQuery(session.topic)) return const SizedBox.shrink();
                final keywords = _findRelatedConceptKeywords(session);
                if (keywords.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('관련 개념으로 다시 배워 보기', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in keywords) ActionChip(label: Text('# $kw'), onPressed: () => onKeywordTap(kw)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Text(_cleanTextForDisplay(content)),
            if (onVisualPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isVisualLoading ? null : onVisualPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(isVisualLoading ? l10n.visualExplanationLoading : l10n.lessonShowMoreDetail),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.score, required this.feedback});

  final int? score;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scoreLabel = score?.toString() ?? '-';
    final chips = <Widget>[
      Chip(
        label: Text(l10n.lessonUnderstandingLabel(scoreLabel)),
        avatar: const Icon(Icons.assessment_outlined),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: chips),
            const SizedBox(height: 12),
            Text(_cleanTextForDisplay(feedback)),
          ],
        ),
      ),
    );
  }
}

class _VisualAidPlan {
  const _VisualAidPlan({required this.needsImage, required this.focus});
  final bool needsImage;
  final String focus;
}

// Removed legacy block that accidentally embedded old code into a string literal.

// Clean LaTeX/Markdown-ish math to readable Unicode text for display
String _cleanTextForDisplay(String text) {
  var cleaned = text;

  // 1) Remove common LaTeX math delimiters but keep content
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\((.*?)\\\)'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$'), (m) => m.group(1) ?? '');
  cleaned = cleaned.replaceAllMapped(RegExp(r'\$(.*?)\$'), (m) => m.group(1) ?? '');

  // 2) Simple LaTeX command replacements
  cleaned = cleaned.replaceAll(r'\times', '×')
                   .replaceAll(r'\div', '÷')
                   .replaceAll(r'\pm', '±')
                   .replaceAll(r'\le', '≤')
                   .replaceAll(r'\ge', '≥')
                   .replaceAll(r'\ne', '≠')
                   .replaceAll(r'\approx', '≈')
                   .replaceAll(r'\pi', 'π')
                   .replaceAll(r'\alpha', 'α')
                  // Removed duplicated imports and corrupted helper block
    _visualCacheKey = null;
    _visualDescription = null;
    _visualFocusHint = null;
    _isVisualLoading = false;
    _visualImageTask = null;
    _visualImage = null;
  }

  _VisualAidPlan _buildVisualAidPlan(LessonSessionProvider session) {
    final topic = (session.topic ?? '').trim();
    final explanation = (session.conceptExplanation ?? '').trim();
                                          await speechService.stopSpeaking();
                                          speechService.setCompletionHandler(
                                            null,
                                          );
                                          if (sheetContext.mounted) {
                                            Navigator.of(sheetContext).pop();
                                          }
                                          if (context.mounted) {
                                            await _showKeywordPreviewAndMaybeStart(
                                              context,
                                              session,
                                              kw,
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      Text(
                        _cleanTextForDisplay(description),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      if (_visualImage != null || _visualImageTask != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildVisualImageWidget(theme),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            speechService.stopSpeaking();
                            speechService.setCompletionHandler(null);
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.close),
                          label: Text(l10n.generalClose),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _looksLikeMathTopic(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;
    final hasNumber = RegExp(r'[0-9]').hasMatch(t);
    final hasOp = RegExp(r'[+\-*/×÷^=(){}\[\]]').hasMatch(t);
    if (hasNumber && hasOp) return true;

    const keywords = [
      '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율', '확률', '통계',
      '평균', '중앙값', '최빈값', '편차', '표준편차',
      '방정식', '연립방정식', '이차방정식', '부등식', '식', '항', '항등식',
      '함수', '그래프', '좌표', '기울기', '절편', '꼭짓점', '최대값', '최소값',
      '도형', '기하', '삼각형', '사각형', '원', '원의', '각도', '사인', '코사인', '탄젠트',
      '넓이', '둘레', '부피', '표면적', '피타고라스',
      '수열', '등차', '등비', '수열의 합',
      '행렬', '벡터', '집합', '확장', '미분', '적분', '극한', '로그', '지수', '다항식',
      '더하기', '덧셈', '빼기', '뺄셈', '곱하기', '곱셈', '나누기', '나눗셈',
      'fraction', 'decimal', 'integer', 'rational', 'irrational', 'ratio', 'proportion', 'percent', 'percentage',
      'probability', 'statistics', 'mean', 'median', 'mode',
      'equation', 'inequality', 'quadratic', 'polynomial', 'function', 'graph', 'coordinate', 'slope', 'intercept',
      'vertex', 'maximum', 'minimum', 'geometry', 'triangle', 'rectangle', 'square', 'circle', 'angle',
      'sine', 'cosine', 'tangent', 'area', 'perimeter', 'volume', 'surface area', 'pythagorean',
      'sequence', 'series', 'arithmetic', 'geometric', 'matrix', 'vector', 'set', 'derivative', 'integral', 'limit', 'log', 'exponential',
    ];

    for (final kw in keywords) {
      if (kw.isEmpty) continue;
      final kwLower = kw.toLowerCase();
      if (t.contains(kwLower) || t.contains(kw)) return true;
    }
    return false;
  }

  Widget _buildVisualImageWidget(ThemeData theme) {
    if (_visualImage != null) {
      final img = _visualImage!;
      if (img.imageBytes != null) {
        return Image.memory(img.imageBytes!, fit: BoxFit.cover);
      }
      if (img.imageUrl != null) {
        return Image.network(
          img.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                    (progress.expectedTotalBytes ?? 1)
                : null;
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(value: value)),
            );
          },
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        );
      }
    }

    if (_visualImageTask != null) {
      return FutureBuilder<VisualExplanationImage?>(
        future: _visualImageTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.data;
          if (result == null) return const SizedBox.shrink();
          _visualImage = result;
          if (result.imageBytes != null) {
            return Image.memory(result.imageBytes!, fit: BoxFit.cover);
          }
          if (result.imageUrl != null) {
            return Image.network(
              result.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }
    return const SizedBox.shrink();
  }

  void _handlePromptChanged(String value, LessonSessionProvider session) {
    _resetGeneratedContent(session);
    final trimmed = value.trim();
    if (trimmed.length >= 6) {
      session.analyzeProblem(trimmed);
    } else if (session.conceptBreakdown.isNotEmpty || session.isAnalyzingConcepts) {
      session.clearConceptSuggestions();
    }
  }

  Future<void> _startLessonWithTopic(
    BuildContext context,
    LessonSessionProvider session,
    String topic,
  ) async {
    if (session.stage == LessonStage.generatingContent ||
        session.stage == LessonStage.evaluating) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reviewRegenerating)),
        );
      }
      return;
    }

    final trimmedTopic = topic.trim();
    final l10n = context.l10n;
    if (trimmedTopic.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.lessonEnterTopicFirst)));
      return;
    }

    final subscription = context.read<SubscriptionProvider>();
    if (!subscription.canAskNewQuestion()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.lessonDailyLimitReached)));
      return;
    }

    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();

    await session.startLesson(
      topic: trimmedTopic,
      difficulty: _selectedDifficulty,
      learnerName:
          auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    subscription.registerQuestionAsked();
    session.clearConceptSuggestions();
    _topicController.text = trimmedTopic;
    if (!mounted) return;
    setState(_resetVisualState);
  }

  @override
  void dispose() {
    _topicController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<LessonSessionProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lessonAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopicCard(context, session),
          const SizedBox(height: 16),
          if (session.conceptExplanation != null)
            _ExplanationCard(
              content: session.conceptExplanation!,
              onVisualPressed: () => _handleVisualExplanation(context, session),
              isVisualLoading: _isVisualLoading,
              onKeywordTap: (kw) async { await _showKeywordPreviewAndMaybeStart(context, session, kw); },
            ),
          const SizedBox(height: 16),
          if (session.conceptExplanation != null)
            _buildEvaluationCard(context, session),
          const SizedBox(height: 16),
          if (session.aiFeedback != null)
            _FeedbackCard(
              score: session.initialScore,
              feedback: session.aiFeedback!,
            ),
          if (session.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                session.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          if (session.requiresEvaluation)
            FilledButton(
              onPressed: () async {
                await session.commitLesson();
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.lessonSaveAndReturn),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, LessonSessionProvider session) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonTellWhatToLearn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: l10n.lessonTopicLabel,
                hintText: l10n.lessonTopicHint,
              ),
              onChanged: (value) => _handlePromptChanged(value, session),
            ),
            if (session.isAnalyzingConcepts)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (!session.isAnalyzingConcepts &&
                session.conceptBreakdown.isNotEmpty)
              _buildConceptHelper(context, session),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('난이도:'),
                Expanded(
                  child: Slider(
                    value: _selectedDifficulty.toDouble(),
                    min: 0,
                    max: 9,
                    divisions: 9,
                    label: '단계 $_selectedDifficulty',
                    onChanged: stage == LessonStage.generatingContent ||
                            stage == LessonStage.evaluating
                        ? null
                        : (value) {
                            final newLevel = value.round();
                            if (newLevel != _selectedDifficulty) {
                              _resetGeneratedContent(session);
                              setState(() => _selectedDifficulty = newLevel);
                            }
                          },
                  ),
                ),
                Text('단계 $_selectedDifficulty'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: stage == LessonStage.generatingContent ||
                          stage == LessonStage.evaluating
                      ? null
                      : () async {
                          final raw = _topicController.text;
                          if (!_looksLikeMathTopic(raw)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.lessonTopicNeedsMath,
                                ),
                              ),
                            );
                            return;
                          }
                          await _startLessonWithTopic(context, session, raw);
                        },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.lessonGenerate),
                ),
                OutlinedButton.icon(
                  onPressed: session.conceptExplanation == null
                      ? null
                      : () async {
                          if (_isSpeaking) {
                            await speech.stopSpeaking();
                            speech.setCompletionHandler(null);
                            setState(() => _isSpeaking = false);
                          } else {
                            setState(() => _isSpeaking = true);
                            final content = session.conceptExplanation!;
                            speech.setCompletionHandler(() {
                              if (mounted) {
                                setState(() => _isSpeaking = false);
                              }
                            });
                            await speech.speakWithAgeAppropriateVoice(
                              content,
                              _selectedDifficulty,
                            );
                          }
                        },
                  icon: Icon(
                    _isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                  ),
                  label: Text(
                    _isSpeaking ? l10n.lessonStopSpeaking : l10n.lessonListen,
                  ),
                ),
              ],
            ),
            if (stage == LessonStage.generatingContent)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptHelper(
    BuildContext context,
    LessonSessionProvider session,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final conceptChips = session.conceptBreakdown
        .map(
          (concept) => ChoiceChip(
            label: Text(concept.name),
            selected: session.selectedConcept == concept,
            onSelected: (selected) {
              if (selected) {
                session.selectConcept(concept);
                if (!_looksLikeMathTopic(concept.name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.lessonTopicNeedsMath)),
                  );
                  return;
                }
                _startLessonWithTopic(context, session, concept.name);
              } else {
                session.deselectConcept();
              }
            },
          ),
        )
        .toList();

    final explanation =
        session.selectedConcept?.summary.trim().isNotEmpty == true
            ? session.selectedConcept!.summary.trim()
            : l10n.lessonConceptNoSelection;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonConceptHelperTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(l10n.lessonConceptHelperHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: conceptChips),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lessonConceptExplanationTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(explanation, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
    BuildContext context,
    LessonSessionProvider session,
  ) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonExplainBack,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final concepts = _findRelatedConceptKeywords(session);
                if (concepts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아래 개념(들)을 직접 설명해 주세요:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in concepts) Chip(label: Text(kw)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: l10n.lessonYourExplanation,
                hintText: '예시: 함수란 무엇인지, 미분이 어떤 의미인지 직접 설명해 주세요.',
              ),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: stage == LessonStage.evaluating
                      ? null
                      : () async {
                          final explanation = _explanationController.text.trim();
                          if (explanation.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.lessonShareExplanationFirst),
                              ),
                            );
                            return;
                          }
                          await session.evaluateUnderstanding(explanation);
                        },
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(l10n.lessonEvaluateUnderstanding),
                ),
                OutlinedButton.icon(
                  onPressed: _isListening
                      ? null
                      : () async {
                          setState(() => _isListening = true);
                          final success = await speech.listen(
                            onFinalResult: (text) {
                              _explanationController.text = text;
                              setState(() => _isListening = false);
                            },
                            onPartialResult: (text) {
                              _explanationController.text = text;
                            },
                          );
                          if (!success) {
                            setState(() => _isListening = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.lessonVoiceUnavailable),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  label: Text(
                    _isListening ? l10n.lessonListening : l10n.lessonSpeakExplanation,
                  ),
                ),
              ],
            ),
            if (session.stage == LessonStage.evaluating)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.content,
    required this.onVisualPressed,
    required this.isVisualLoading,
    required this.onKeywordTap,
  });

  final String content;
  final VoidCallback? onVisualPressed;
  final bool isVisualLoading;
  final void Function(String keyword) onKeywordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (ctx) {
                final session = ctx.read<LessonSessionProvider>();
                if (_isGenericConceptQuery(session.topic)) {
                  return const SizedBox.shrink();
                }
                final keywords = _findRelatedConceptKeywords(session);
                if (keywords.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관련 개념으로 다시 배워 보기',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in keywords)
                          ActionChip(
                            label: Text('# $kw'),
                            onPressed: () => onKeywordTap(kw),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Text(_cleanTextForDisplay(content)),
            if (onVisualPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isVisualLoading ? null : onVisualPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    isVisualLoading
                        ? l10n.visualExplanationLoading
                        : l10n.lessonShowMoreDetail,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* CLEAN END OF FILE MARKER - no legacy content below */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Clean LaTeX and markdown syntax from text for better display readability
String _cleanTextForDisplay(String text) {
  var cleaned = text;

  // Remove inline LaTeX delimiters: \( ... \) but keep the content
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\\((.*?)\\\)'),
    String _cleanTextForDisplay(String text) {
      var cleaned = text;

      // Remove inline LaTeX delimiters: \( ... \) but keep the content
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\\\((.*?)\\\)'),
        (match) => match.group(1) ?? '',
      );

      // Remove display LaTeX delimiters: \[ ... \] but keep the content
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\\\[(.*?)\\\]'),
        (match) => match.group(1) ?? '',
      );

      // Remove dollar sign math delimiters: $ ... $ but keep the content
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\$(.*?)\$'),
        (match) => match.group(1) ?? '',
      );

      // Remove double dollar sign: $$ ... $$ but keep the content
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\$\$(.*?)\$\$'),
        (match) => match.group(1) ?? '',
      );

      // Remove LaTeX commands and replace with readable alternatives
      cleaned = cleaned.replaceAll(r'\times', '×');
      cleaned = cleaned.replaceAll(r'\div', '÷');
      cleaned = cleaned.replaceAll(r'\pm', '±');
      cleaned = cleaned.replaceAll(r'\le', '≤');
      cleaned = cleaned.replaceAll(r'\ge', '≥');
      cleaned = cleaned.replaceAll(r'\ne', '≠');
      cleaned = cleaned.replaceAll(r'\approx', '≈');
      cleaned = cleaned.replaceAll(r'\pi', 'π');
      cleaned = cleaned.replaceAll(r'\alpha', 'α');
      cleaned = cleaned.replaceAll(r'\beta', 'β');
      cleaned = cleaned.replaceAll(r'\theta', 'θ');
      cleaned = cleaned.replaceAll(r'\sqrt', '√');

      // Convert common fractions to Unicode fraction characters
      cleaned = cleaned.replaceAll('1/2', '½');
      cleaned = cleaned.replaceAll('1/3', '⅓');
      cleaned = cleaned.replaceAll('2/3', '⅔');
      cleaned = cleaned.replaceAll('1/4', '¼');
      cleaned = cleaned.replaceAll('3/4', '¾');
      cleaned = cleaned.replaceAll('1/5', '⅕');
      cleaned = cleaned.replaceAll('2/5', '⅖');
      cleaned = cleaned.replaceAll('3/5', '⅗');
      cleaned = cleaned.replaceAll('4/5', '⅘');
      cleaned = cleaned.replaceAll('1/6', '⅙');
      cleaned = cleaned.replaceAll('5/6', '⅚');
      cleaned = cleaned.replaceAll('1/8', '⅛');
      cleaned = cleaned.replaceAll('3/8', '⅜');
      cleaned = cleaned.replaceAll('5/8', '⅝');
      cleaned = cleaned.replaceAll('7/8', '⅞');

      // Handle LaTeX fraction notation: \frac{numerator}{denominator}
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\\frac\s*\{([^}]*)\}\s*\{([^}]*)\}'),
        (match) {
          final numerator = match.group(1)?.trim() ?? '';
          final denominator = match.group(2)?.trim() ?? '';

          // Try to convert to Unicode fraction if it's a common one
          final fraction = '$numerator/$denominator';
          const unicodeFractions = {
            '1/2': '½',
            '1/3': '⅓',
            '2/3': '⅔',
            '1/4': '¼',
            '3/4': '¾',
            '1/5': '⅕',
            '2/5': '⅖',
            '3/5': '⅗',
            '4/5': '⅘',
            '1/6': '⅙',
            '5/6': '⅚',
            '1/8': '⅛',
            '3/8': '⅜',
            '5/8': '⅝',
            '7/8': '⅞',
          };

          if (unicodeFractions.containsKey(fraction)) {
            return unicodeFractions[fraction]!;
          }

          // For other fractions, use clear notation with parentheses if needed
          return '($numerator)/($denominator)';
        },
      );

      // Replace double asterisks (markdown bold) with nothing
      cleaned = cleaned.replaceAll('**', '');

      // Handle square root notation: \sqrt{x} -> √(x) or √x for simple cases
      cleaned = cleaned.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^}]*)\}'), (match) {
        final content = match.group(1)?.trim() ?? '';
        // If content has operators, add parentheses for clarity
        if (content.contains(RegExp(r'[+\-*/]'))) {
          return '√($content)';
        }
        return '√$content';
      });

      // Handle nth root: \sqrt[n]{x} -> ⁿ√(x)
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'\\sqrt\s*\[([^\]]*)\]\s*\{([^}]*)\}'),
        (match) {
          final root = match.group(1)?.trim() ?? '';
          final content = match.group(2)?.trim() ?? '';

          // Convert root to superscript
          String toSuperscript(String s) {
            const map = {
              '0': '⁰',
              '1': '¹',
              '2': '²',
              '3': '³',
              '4': '⁴',
              '5': '⁵',
              '6': '⁶',
              '7': '⁷',
              '8': '⁸',
              '9': '⁹',
            };
            return s.split('').map((c) => map[c] ?? c).join('');
          }

          final rootSuper = toSuperscript(root);
          if (content.contains(RegExp(r'[+\-*/]'))) {
            return '$rootSuper√($content)';
          }
          return '$rootSuper√$content';
        },
      );

      // Remove remaining LaTeX commands (backslash followed by letters)
      cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');

      // Remove extra backslashes
      cleaned = cleaned.replaceAll(RegExp(r'\\'), '');

      // Remove curly braces used in LaTeX but keep content
      cleaned = cleaned.replaceAll('{', '');
      cleaned = cleaned.replaceAll('}', '');

      // Render common math notations more readably
      // 1) Convert simple caret exponents to Unicode superscripts
      String toSuperscript(String exp) {
        const map = {
          '0': '⁰',
          '1': '¹',
          '2': '²',
          '3': '³',
          '4': '⁴',
          '5': '⁵',
          '6': '⁶',
          '7': '⁷',
          '8': '⁸',
          '9': '⁹',
          '+': '⁺',
          '-': '⁻',
          '(': '⁽',
          ')': '⁾',
        };
        return exp.split('').map((c) => map[c] ?? c).join('');
      }

      cleaned = cleaned.replaceAllMapped(
        RegExp(r'([A-Za-z0-9\)])\^(-?\d{1,3})'),
        (m) => '${m.group(1)}${toSuperscript(m.group(2)!)}',
      );

      // 2) Subscripts for simple indices: a_1 -> a₁
      String toSubscript(String digits) {
        const map = {
          '0': '₀',
          '1': '₁',
          '2': '₂',
          '3': '₃',
          '4': '₄',
          '5': '₅',
          '6': '₆',
          '7': '₇',
          '8': '₈',
          '9': '₉',
          '+': '₊',
          '-': '₋',
          '(': '₍',
          ')': '₎',
        };
        return digits.split('').map((c) => map[c] ?? c).join('');
      }

      cleaned = cleaned.replaceAllMapped(
        RegExp(r'([A-Za-zπθαβ])_(\d{1,3})'),
        (m) => '${m.group(1)}${toSubscript(m.group(2)!)}',
      );

      // Improve multiplication display: 2*3 -> 2×3, but keep * in expressions like a*b
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(\d)\s*\*\s*(\d)'),
        (m) => '${m.group(1)}×${m.group(2)}',
      );

      // Add spacing around operators for better readability
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'(\d)([\+\-×÷])(\d)'),
        (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)}',
      );

      // Clean up multiple consecutive spaces on the same line (but preserve line breaks)
      cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

      // Normalize line breaks: replace multiple consecutive line breaks with double line break
      cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

      // Trim each line to remove trailing spaces
      cleaned = cleaned.split('\n').map((line) => line.trim()).join('\n');

      // Trim overall
      cleaned = cleaned.trim();

      return cleaned;
    }
  '함수', '삼각함수', '지수함수', '로그함수', '그래프', '좌표', '기울기', '절편', '꼭짓점',
  // Arithmetic & numbers
  '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율',
  // Geometry
  '도형', '기하', '삼각형', '사각형', '원', '원의 넓이', '둘레', '피타고라스', '벡터', '행렬',
  // Calculus
  '미분', '적분', '극한',
  // Probability & statistics
  '확률', '통계', '평균', '중앙값', '최빈값', '표준편차',
  // Trig details
  '사인', '코사인', '탄젠트',
  // Others
  '로그', '지수', '집합',
];

bool _containsNumberOrOperator(String s) =>
    RegExp(r'[0-9+\-*/×÷=^]').hasMatch(s);

// Topic like just a keyword? If so, we can opt to hide suggestions block
bool _isGenericConceptQuery(String? topic) {
  final t = (topic ?? '').trim();
  if (t.isEmpty) return false;
  if (_containsNumberOrOperator(t)) return false; // it's a problem-like query
  // Exact or close match to known keywords
  if (_knownConceptKeywords.contains(t)) return true;
  // Also treat short keyword-like topics as generic
  if (t.length <= 6 &&
      _knownConceptKeywords.any((k) => t == k || k.contains(t))) {
    return true;
  }
  return false;
}

List<String> _extractConceptKeywordsFromText(String text) {
  final lower = text.toLowerCase();
  final results = <String>{};
  for (final kw in _knownConceptKeywords) {
    if (kw.isEmpty) continue;
    // Check both original and lower-cased (mainly for English words)
    if (text.contains(kw)) {
      results.add(kw);
      continue;
    }
    final kwLower = kw.toLowerCase();
    if (lower.contains(kwLower)) {
      results.add(kw);
    }
  }
  return results.toList(growable: false);
}

List<String> _findRelatedConceptKeywords(LessonSessionProvider session) {
  // Prefer AI-provided breakdowns when available
  final fromBreakdown = session.conceptBreakdown
      .map((c) => c.name.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final set = <String>{...fromBreakdown};
  if (set.isEmpty) {
    final topic = session.topic ?? '';
    final explanation = session.conceptExplanation ?? '';
    final combined = '$topic\n$explanation';
    set.addAll(_extractConceptKeywordsFromText(combined));
  }
  // Remove current topic if it matches exactly
  final t = (session.topic ?? '').trim();
  set.removeWhere((e) => e == t);
  return set.take(8).toList(growable: false);
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _topicController = TextEditingController();
  final _explanationController = TextEditingController();
  int _selectedDifficulty = 0;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isVisualLoading = false;
  String? _visualCacheKey;
  String? _visualDescription;
  String? _visualFocusHint;
  Future<VisualExplanationImage?>? _visualImageTask;
  VisualExplanationImage? _visualImage;

  // Build a brief, friendly summary for a keyword using existing breakdown or AI fallback
  Future<String> _buildBriefSummaryForKeyword(
    BuildContext context,
    String keyword,
    LessonSessionProvider session,
  ) async {
    String? summary;
    // 1) Try to find from current breakdown (exact match preferred)
    final exact = session.conceptBreakdown
        .firstWhere(
          (c) => c.name.trim() == keyword.trim(),
          orElse: () => const ConceptBreakdown(name: '', summary: ''),
        )
        .summary
        .trim();
    if (exact.isNotEmpty) summary = exact;
    // 2) Otherwise, try partial match
    summary ??= session.conceptBreakdown
        .firstWhere(
          (c) => c.name.contains(keyword) || keyword.contains(c.name),
          orElse: () => const ConceptBreakdown(name: '', summary: ''),
        )
        .summary
        .trim();

    // 3) Fallback to AI quick explanation
    if (summary.isEmpty) {
      final ai = context.read<AiContentService>();
      final learnerName =
          context.read<AuthProvider>().currentUser?.displayName ??
          context.l10n.generalLearnerFallback;
      try {
        final full = await ai.explainConcept(
          topic: keyword,
          difficulty: _selectedDifficulty,
          learnerName: learnerName,
        );
        summary = _cleanTextForDisplay(full);
      } catch (_) {
        summary = '$keyword을(를) 간단히 다시 배워 볼까요? 핵심 아이디어를 짧게 정리해 드릴게요.';
      }
    }

    // Trim to a short preview (about 240 chars / ~3 lines)
    String trimmed = summary;
    if (trimmed.length > 240) {
      trimmed = trimmed.substring(0, 240).trimRight();
      if (!trimmed.endsWith('…')) trimmed = '$trimmed…';
    }
    final lines = trimmed.split('\n');
    if (lines.length > 4) {
      trimmed = lines.take(4).join('\n');
    }
    return trimmed;
  }

  Future<void> _showKeywordPreviewAndMaybeStart(
    BuildContext context,
    LessonSessionProvider session,
    String keyword,
  ) async {
  // Capture theme/l10n before async gap to avoid context misuse warning
  final theme = Theme.of(context);
  final l10n = context.l10n;

    // Prepare preview text (may call AI)
    final preview = await _buildBriefSummaryForKeyword(
      context,
      keyword,
      session,
    );

  if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('# $keyword', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                Text(
                  _cleanTextForDisplay(preview),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        child: Text(l10n.generalClose),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          // If content is currently generating/evaluating, block and inform
                          if (session.stage == LessonStage.generatingContent ||
                              session.stage == LessonStage.evaluating) {
                            if (sheetCtx.mounted) {
                              ScaffoldMessenger.of(sheetCtx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.reviewRegenerating,
                                  ),
                                ),
                              );
                            }
                            return;
                          }

                          // Close the preview sheet first
                          Navigator.of(sheetCtx).pop();
                          // Immediate feedback that a new lesson is starting
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"$keyword" 주제로 새 수업을 시작해요.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                          // Fill the input for visual feedback
                          _topicController.text = keyword;
                          try {
                            await _startLessonWithTopic(
                              context,
                              session,
                              keyword,
                            );
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.l10n.lessonGenerationError,
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          if (context.mounted) {
                            // Return to main after starting the new lesson
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          }
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text('이 개념으로 새 수업 시작'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _resetGeneratedContent(LessonSessionProvider session) {
    if (_isListening) {
      setState(() => _isListening = false);
    }

    final disallowResetStages = {
      LessonStage.generatingContent,
      LessonStage.evaluating,
    };

    if (disallowResetStages.contains(session.stage)) {
      return;
    }

    final hasGeneratedContent =
        session.conceptExplanation != null ||
        session.aiFeedback != null ||
        session.requiresEvaluation ||
        session.stage == LessonStage.ready ||
        session.stage == LessonStage.awaitingEvaluation ||
        session.stage == LessonStage.completed;

    final hasUserExplanation = _explanationController.text.isNotEmpty;

    if (!hasGeneratedContent && !hasUserExplanation) {
      return;
    }

    session.reset();
    _explanationController.clear();
    setState(_resetVisualState);
  }

  void _resetVisualState() {
    _visualCacheKey = null;
    _visualDescription = null;
    _visualFocusHint = null;
    _isVisualLoading = false;
    _visualImageTask = null;
    _visualImage = null;
  }

  _VisualAidPlan _buildVisualAidPlan(LessonSessionProvider session) {
    final topic = (session.topic ?? '').trim();
    final explanation = (session.conceptExplanation ?? '').trim();
    final raw = '$topic\n$explanation';
    final lower = raw.toLowerCase();
    final baseConcept =
        (session.selectedConcept?.name ?? session.detectedConcept ?? topic)
            .trim();
    final fallbackFocus = baseConcept.isNotEmpty
        ? '$baseConcept을 떠올릴 수 있는 간단한 그림을 제안해 주세요.'
        : '핵심 개념을 떠올릴 수 있는 간단한 그림을 제안해 주세요.';

    if (_containsAny(lower, [
      'graph',
      'coordinate',
      'function',
      'equation',
      'linear',
      'quadratic',
      'plot',
      'slope',
      '\uadf8\ub798\ud504',
      '\uc88c\ud45c',
      '\ud568\uc218',
      '\ubc29\uc815\uc2dd',
    ])) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '그래프, 좌표, 함수 등 시각적 개념을 설명하는 그림을 제안해 주세요.',
      );
    }
    if (_containsAny(lower, [
          'difference',
          'subtract',
          '\ube7c\uc148',
          '\ube7c\uae30',
        ]) ||
        raw.contains('-')) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '모둠에서 물건을 빼는 장면을 그려 남은 양이 분명하게 보이도록 해 주세요.',
      );
    }
    if (_containsAny(lower, [
      'multiplication',
      'times',
      'array',
      '\uacf1\uc148',
      '\uacf1\ud558\uae30',
      '\ubc30\uc218',
    ])) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '배열(격자)을 사용해 곱셈을 설명하고, 행과 열에 라벨을 달아 주세요.',
      );
    }
    if (_containsAny(lower, [
      'area',
      'shape',
      'circle',
      'rectangle',
      'square',
      'perimeter',
      '\uba74\uc801',
      '\ub113\uc774',
      '\ub3c4\ud615',
      '\uc0ac\uac01\ud615',
      '\uc6d0',
      '\ubc18\uc9c0\ub984',
    ])) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '관련 도형을 그리고 길이·각도·넓이 등을 표시하여 개념을 설명해 주세요.',
      );
    }
    if (_containsAny(lower, [
          'ratio',
          'percent',
          'probability',
          'statistics',
          '\ube44\uc728',
          '\ubc31\ubd84\uc728',
          '\ud655\ub960',
          '\ud1b5\uacc4',
          '\ub370\uc774\ud130',
        ]) ||
        raw.contains('%')) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '막대그래프 또는 파이차트로 비율을 명확하게 비교해 주세요.',
      );
    }
    if (_containsAny(lower, [
      'number line',
      'timeline',
      '\uc218\uc9dd\uc120',
      '\uc2dc\uac04',
    ])) {
      return _VisualAidPlan(
        needsImage: true,
        focus: '눈금이 있는 수직선을 그리고 설명에 사용된 주요 지점을 강조해 주세요.',
      );
    }
    return _VisualAidPlan(needsImage: false, focus: fallbackFocus);
  }

  bool _containsAny(String text, Iterable<String> keywords) {
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _handleVisualExplanation(
    BuildContext context,
    LessonSessionProvider session,
  ) async {
    if (_isVisualLoading) {
      return;
    }

    final topic = session.topic;
    final explanation = session.conceptExplanation;
    if (topic == null || explanation == null) {
      return;
    }

    final plan = _buildVisualAidPlan(session);
    final focus = plan.focus;
    final cacheKey = '$topic|$focus|${session.targetAge}';

    if (_visualCacheKey == cacheKey && _visualDescription != null) {
      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
      return;
    }

    final aiService = context.read<AiContentService>();
    final learnerName =
        context.read<AuthProvider>().currentUser?.displayName ??
        context.l10n.generalLearnerFallback;
    final messenger = ScaffoldMessenger.of(context);
    final visualErrorMessage = context.l10n.visualExplanationError;

    setState(() {
      _isVisualLoading = true;
    });

    try {
      final result = await aiService.createVisualExplanation(
        topic: topic,
        difficulty: session.targetAge,
        learnerName: learnerName,
        requestImage: plan.needsImage,
        imageFocus: focus,
        baseExplanation: explanation,
      );

      if (!mounted) return;

      setState(() {
        _visualCacheKey = cacheKey;
        _visualDescription = result.description;
        _visualFocusHint = focus;
        _visualImageTask = result.imageTask;
        // If an immediate image is available (future-less), cache it
        if (result.imageBytes != null || result.imageUrl != null) {
          _visualImage = VisualExplanationImage(
            imageBytes: result.imageBytes,
            imageUrl: result.imageUrl,
          );
        } else {
          _visualImage = null;
        }
      });

      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
    } catch (error, stackTrace) {
      debugPrint('Visual explanation failed: $error\n$stackTrace');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(visualErrorMessage)));
    } finally {
      if (mounted) {
        setState(() => _isVisualLoading = false);
      }
    }
  }

  Future<void> _presentVisualExplanationSheet(
    BuildContext context,
    LessonSessionProvider session,
    String focus,
  ) async {
    final description = _visualDescription;
    final topic = session.topic;
    if (description == null || topic == null || !context.mounted) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolvedFocus = focus.trim().isNotEmpty
        ? focus.trim()
        : (_visualFocusHint?.trim() ??
              session.selectedConcept?.name ??
              session.topic ??
              '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool isSpeaking = false;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final speechService = context.read<SpeechService>();

            // Set completion handler to update state when TTS finishes
            speechService.setCompletionHandler(() {
              if (ctx.mounted) {
                setSheetState(() {
                  isSpeaking = false;
                });
              }
            });

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.visualExplanationTitle,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: () async {
                              if (isSpeaking) {
                                await speechService.stopSpeaking();
                                setSheetState(() {
                                  isSpeaking = false;
                                });
                              } else {
                                setSheetState(() {
                                  isSpeaking = true;
                                });
                                await speechService
                                    .speakWithAgeAppropriateVoice(
                                      description,
                                      session.targetAge,
                                    );
                              }
                            },
                            icon: Icon(
                              isSpeaking
                                  ? Icons.stop
                                  : Icons.volume_up_outlined,
                            ),
                            tooltip: isSpeaking
                                ? l10n.lessonStopSpeaking
                                : l10n.lessonListen,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (resolvedFocus.isNotEmpty) ...[
                        Text(
                          _cleanTextForDisplay(
                            l10n.visualExplanationFocus(resolvedFocus),
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Related concept keywords chips (tap to start a new lesson)
                      if (!_isGenericConceptQuery(topic))
                        Builder(
                          builder: (context) {
                            final keywords = _findRelatedConceptKeywords(
                              session,
                            );
                            if (keywords.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '이 문제를 풀기 전에 알아두면 좋은 개념',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final kw in keywords)
                                      ActionChip(
                                        label: Text('# $kw'),
                                        onPressed: () async {
                                          await speechService.stopSpeaking();
                                          speechService.setCompletionHandler(
                                            null,
                                          );
                                          if (sheetContext.mounted) {
                                            Navigator.of(sheetContext).pop();
                                          }
                                          if (context.mounted) {
                                            await _showKeywordPreviewAndMaybeStart(
                                              context,
                                              session,
                                              kw,
                                            );
                                          }
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            );
                          },
                        ),
                      Text(
                        _cleanTextForDisplay(description),
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      // Optional illustrative image (if available/requested)
                      if (_visualImage != null || _visualImageTask != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildVisualImageWidget(theme),
                        ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {
                            speechService.stopSpeaking();
                            speechService.setCompletionHandler(null);
                            Navigator.of(sheetContext).pop();
                          },
                          icon: const Icon(Icons.close),
                          label: Text(l10n.generalClose),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Heuristic: does user's topic look like a math concept or problem?
  bool _looksLikeMathTopic(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;

    // Contains numbers and math operators or equality signs
    final hasNumber = RegExp(r'[0-9]').hasMatch(t);
    final hasOp = RegExp(r'[+\-*/×÷^=(){}\[\]]').hasMatch(t);
    if (hasNumber && hasOp) return true;

    // Common math keywords (Korean + English)
    const keywords = [
      // Korean
      '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율', '확률', '통계',
      '평균', '중앙값', '최빈값', '편차', '표준편차',
      '방정식', '연립방정식', '이차방정식', '부등식', '식', '항', '항등식',
      '함수', '그래프', '좌표', '기울기', '절편', '꼭짓점', '최대값', '최소값',
      '도형', '기하', '삼각형', '사각형', '원', '원의', '각도', '사인', '코사인', '탄젠트',
      '넓이', '둘레', '부피', '표면적', '피타고라스',
      '수열', '등차', '등비', '수열의 합',
      '행렬', '벡터', '집합', '확장', '미분', '적분', '극한', '로그', '지수', '다항식',
      // 연산 관련 단어
      '더하기', '덧셈', '빼기', '뺄셈', '곱하기', '곱셈', '나누기', '나눗셈',
      // English
      'fraction',
      'decimal',
      'integer',
      'rational',
      'irrational',
      'ratio',
      'proportion',
      'percent',
      'percentage',
      'probability',
      'statistics',
      'mean',
      'median',
      'mode',
      'equation', 'inequality', 'quadratic', 'polynomial',
      'function',
      'graph',
      'coordinate',
      'slope',
      'intercept',
      'vertex',
      'maximum',
      'minimum',
      'geometry',
      'triangle',
      'rectangle',
      'square',
      'circle',
      'angle',
      'sine',
      'cosine',
      'tangent',
      'area', 'perimeter', 'volume', 'surface area', 'pythagorean',
      'sequence', 'series', 'arithmetic', 'geometric',
      'matrix',
      'vector',
      'set',
      'derivative',
      'integral',
      'limit',
      'log',
      'exponential',
    ];

    // Match against known keywords (both original and lowercase)
    for (final kw in keywords) {
      if (kw.isEmpty) continue;
      final kwLower = kw.toLowerCase();
      if (t.contains(kwLower) || t.contains(kw)) return true;
    }

    return false;
  }

  Widget _buildVisualImageWidget(ThemeData theme) {
    // If we already have an image cached, show it immediately
    if (_visualImage != null) {
      final img = _visualImage!;
      if (img.imageBytes != null) {
        return Image.memory(img.imageBytes!, fit: BoxFit.cover);
      }
      if (img.imageUrl != null) {
        return Image.network(
          img.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                      (progress.expectedTotalBytes ?? 1)
                : null;
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(value: value)),
            );
          },
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        );
      }
    }

    // Otherwise, if there's a task, build with FutureBuilder
    if (_visualImageTask != null) {
      return FutureBuilder<VisualExplanationImage?>(
        future: _visualImageTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.data;
          if (result == null) {
            return const SizedBox.shrink();
          }
          _visualImage = result; // cache for next time
          if (result.imageBytes != null) {
            return Image.memory(result.imageBytes!, fit: BoxFit.cover);
          }
          if (result.imageUrl != null) {
            return Image.network(
              result.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _handlePromptChanged(String value, LessonSessionProvider session) {
    _resetGeneratedContent(session);
    final trimmed = value.trim();
    if (trimmed.length >= 6) {
      session.analyzeProblem(trimmed);
    } else if (session.conceptBreakdown.isNotEmpty ||
        session.isAnalyzingConcepts) {
      session.clearConceptSuggestions();
    }
  }

  Future<void> _startLessonWithTopic(
    BuildContext context,
    LessonSessionProvider session,
    String topic,
  ) async {
    if (session.stage == LessonStage.generatingContent ||
        session.stage == LessonStage.evaluating) {
      // Inform the user that starting a new lesson is blocked right now
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.reviewRegenerating)),
        );
      }
      return;
    }

    final trimmedTopic = topic.trim();
    final l10n = context.l10n;
    if (trimmedTopic.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.lessonEnterTopicFirst)));
      return;
    }

    final subscription = context.read<SubscriptionProvider>();
    if (!subscription.canAskNewQuestion()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.lessonDailyLimitReached)));
      return;
    }

    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();

    await session.startLesson(
      topic: trimmedTopic,
      difficulty: _selectedDifficulty,
      learnerName:
          auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    subscription.registerQuestionAsked();
    session.clearConceptSuggestions();
    _topicController.text = trimmedTopic;
    if (!mounted) return;
    setState(_resetVisualState);
  }

  Widget _buildTopicCard(BuildContext context, LessonSessionProvider session) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonTellWhatToLearn,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: InputDecoration(
                labelText: l10n.lessonTopicLabel,
                hintText: l10n.lessonTopicHint,
              ),
              onChanged: (value) => _handlePromptChanged(value, session),
            ),
            if (session.isAnalyzingConcepts)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
            if (!session.isAnalyzingConcepts &&
                session.conceptBreakdown.isNotEmpty)
              _buildConceptHelper(context, session),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('난이도:'),
                Expanded(
                  child: Slider(
                    value: _selectedDifficulty.toDouble(),
                    min: 0,
                    max: 9,
                    divisions: 9,
                    label: '단계 $_selectedDifficulty',
                    onChanged:
                        stage == LessonStage.generatingContent ||
                            stage == LessonStage.evaluating
                        ? null
                        : (value) {
                            final newLevel = value.round();
                            if (newLevel != _selectedDifficulty) {
                              _resetGeneratedContent(session);
                              setState(() => _selectedDifficulty = newLevel);
                            }
                          },
                  ),
                ),
                Text('단계 $_selectedDifficulty'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      stage == LessonStage.generatingContent ||
                          stage == LessonStage.evaluating
                      ? null
                      : () async {
                          final raw = _topicController.text;
                          if (!_looksLikeMathTopic(raw)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.lessonTopicNeedsMath,
                                ),
                              ),
                            );
                            return;
                          }
                          await _startLessonWithTopic(context, session, raw);
                        },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.lessonGenerate),
                ),
                OutlinedButton.icon(
                  onPressed: session.conceptExplanation == null
                      ? null
                      : () async {
                          if (_isSpeaking) {
                            // Stop speaking
                            await speech.stopSpeaking();
                            speech.setCompletionHandler(null);
                            setState(() => _isSpeaking = false);
                          } else {
                            // Start speaking
                            setState(() => _isSpeaking = true);
                            final content = session.conceptExplanation!;
                            speech.setCompletionHandler(() {
                              if (mounted) {
                                setState(() => _isSpeaking = false);
                              }
                            });
                            await speech.speakWithAgeAppropriateVoice(
                              content,
                              _selectedDifficulty,
                            );
                          }
                        },
                  icon: Icon(
                    _isSpeaking ? Icons.stop : Icons.volume_up_outlined,
                  ),
                  label: Text(
                    _isSpeaking ? l10n.lessonStopSpeaking : l10n.lessonListen,
                  ),
                ),
              ],
            ),
            if (stage == LessonStage.generatingContent)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptHelper(
    BuildContext context,
    LessonSessionProvider session,
  ) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final conceptChips = session.conceptBreakdown
        .map(
          (concept) => ChoiceChip(
            label: Text(concept.name),
            selected: session.selectedConcept == concept,
            onSelected: (selected) {
              if (selected) {
                session.selectConcept(concept);
                if (!_looksLikeMathTopic(concept.name)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.lessonTopicNeedsMath)),
                  );
                  return;
                }
                _startLessonWithTopic(context, session, concept.name);
              } else {
                session.deselectConcept();
              }
            },
          ),
        )
        .toList();

    final explanation =
        session.selectedConcept?.summary.trim().isNotEmpty == true
        ? session.selectedConcept!.summary.trim()
        : l10n.lessonConceptNoSelection;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.lessonConceptHelperTitle,
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(l10n.lessonConceptHelperHint, style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: conceptChips),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.lessonConceptExplanationTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Text(explanation, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(
    BuildContext context,
    LessonSessionProvider session,
  ) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonExplainBack,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Show required concept keywords for explanation guidance
            Builder(
              builder: (ctx) {
                final concepts = _findRelatedConceptKeywords(session);
                if (concepts.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '아래 개념(들)을 직접 설명해 주세요:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in concepts) Chip(label: Text(kw)),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: l10n.lessonYourExplanation,
                hintText: '예시: 함수란 무엇인지, 미분이 어떤 의미인지 직접 설명해 주세요.',
              ),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: stage == LessonStage.evaluating
                      ? null
                      : () async {
                          final explanation = _explanationController.text
                              .trim();
                          if (explanation.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.lessonShareExplanationFirst),
                              ),
                            );
                            return;
                          }
                          await session.evaluateUnderstanding(explanation);
                        },
                  icon: const Icon(Icons.analytics_outlined),
                  label: Text(l10n.lessonEvaluateUnderstanding),
                ),
                OutlinedButton.icon(
                  onPressed: _isListening
                      ? null
                      : () async {
                          setState(() => _isListening = true);
                          final success = await speech.listen(
                            onFinalResult: (text) {
                              _explanationController.text = text;
                              setState(() => _isListening = false);
                            },
                            onPartialResult: (text) {
                              _explanationController.text = text;
                            },
                          );
                          if (!success) {
                            setState(() => _isListening = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.lessonVoiceUnavailable),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  label: Text(
                    _isListening
                        ? l10n.lessonListening
                        : l10n.lessonSpeakExplanation,
                  ),
                ),
              ],
            ),
            if (session.stage == LessonStage.evaluating)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _topicController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<LessonSessionProvider>();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.lessonAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopicCard(context, session),
          const SizedBox(height: 16),
          if (session.conceptExplanation != null)
            _ExplanationCard(
              content: session.conceptExplanation!,
              onVisualPressed: () => _handleVisualExplanation(context, session),
              isVisualLoading: _isVisualLoading,
              onKeywordTap: (kw) async {
                await _showKeywordPreviewAndMaybeStart(
                  context,
                  session,
                  kw,
                );
              },
            ),
          const SizedBox(height: 16),
          if (session.conceptExplanation != null)
            _buildEvaluationCard(context, session),
          const SizedBox(height: 16),
          if (session.aiFeedback != null)
            _FeedbackCard(
              score: session.initialScore,
              feedback: session.aiFeedback!,
            ),
          if (session.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                session.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          if (session.requiresEvaluation)
            FilledButton(
              onPressed: () async {
                await session.commitLesson();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l10n.lessonSaveAndReturn),
            ),
        ],
      ),
    );
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.content,
    required this.onVisualPressed,
    required this.isVisualLoading,
    required this.onKeywordTap,
  });

  final String content;
  final VoidCallback? onVisualPressed;
  final bool isVisualLoading;
  final void Function(String keyword) onKeywordTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.lessonExplanationTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // Suggest related concept keywords at the top of the explanation
            Builder(
              builder: (ctx) {
                final session = ctx.read<LessonSessionProvider>();
                if (_isGenericConceptQuery(session.topic)) {
                  return const SizedBox.shrink();
                }
                final keywords = _findRelatedConceptKeywords(session);
                if (keywords.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관련 개념으로 다시 배워 보기',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in keywords)
                          ActionChip(
                            label: Text('# $kw'),
                            onPressed: () => onKeywordTap(kw),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Text(_cleanTextForDisplay(content)),
            if (onVisualPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isVisualLoading ? null : onVisualPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    isVisualLoading
                        ? l10n.visualExplanationLoading
                        : l10n.lessonShowMoreDetail,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.score, required this.feedback});

  final int? score;
  final String feedback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scoreLabel = score?.toString() ?? '-';
    final chips = <Widget>[
      Chip(
        label: Text(l10n.lessonUnderstandingLabel(scoreLabel)),
        avatar: const Icon(Icons.assessment_outlined),
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: chips),
            const SizedBox(height: 12),
            Text(_cleanTextForDisplay(feedback)),
          ],
        ),
      ),
    );
  }
}

class _VisualAidPlan {
  const _VisualAidPlan({required this.needsImage, required this.focus});

  final bool needsImage;
  final String focus;
}
''';

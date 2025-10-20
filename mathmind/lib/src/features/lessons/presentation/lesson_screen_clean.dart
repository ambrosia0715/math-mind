import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/math_text.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _topicController = TextEditingController();
  final _explanationController = TextEditingController();
  // 1(쉬움) ~ 10(어려움). 기본 10으로 표기
  int _selectedDifficulty = 10;
  bool _isSpeaking = false;
  bool _isListening = false;
  String? _lastUserId;
  String? _lastCountedTopic;
  bool _didInitialReset = false;

  // 내부 AI용 난이도 매핑: 0(쉬움) ~ 9(어려움)
  int get _aiDifficulty => (_selectedDifficulty - 1).clamp(0, 9);

  @override
  void dispose() {
    _topicController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 처음 진입 시 화면/세션 초기화 (맞춤형 수업 시작 진입 시 깨끗한 상태 보장)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didInitialReset) return;
      try {
        final session = context.read<LessonSessionProvider>();
        session.reset();
      } catch (_) {
        // 테스트/특수 환경에서 LessonSessionProvider 미주입 시 무시
      }
      _topicController.clear();
      _explanationController.clear();
      _isSpeaking = false;
      _isListening = false;
      _lastCountedTopic = null;
      try {
        final auth = context.read<AuthProvider>();
        _lastUserId = auth.currentUser?.id;
      } catch (_) {
        // AuthProvider가 제공되지 않은 테스트/특수 환경에서는 무시
        _lastUserId = null;
      }
      _didInitialReset = true;
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 계정 변경 시 전체 초기화
    String? uid;
    try {
      final auth = context.read<AuthProvider>();
      uid = auth.currentUser?.id;
    } catch (_) {
      uid = null;
    }
    if (_lastUserId != null && _lastUserId != uid) {
      final session = context.read<LessonSessionProvider>();
      session.reset();
      _topicController.clear();
      _explanationController.clear();
      _isSpeaking = false;
      _isListening = false;
      _lastCountedTopic = null;
      _lastUserId = uid;
      if (mounted) setState(() {});
    } else if (_lastUserId == null) {
      _lastUserId = uid;
    }
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    LessonSessionProvider? session;
    try {
      session = context.watch<LessonSessionProvider>();
    } catch (_) {
      session = null; // 테스트/특수 환경에서 Provider 미주입 시에도 최소 UI 렌더링
    }
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.lessonAppBarTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTopicCard(context, session),
          const SizedBox(height: 16),
          if (session?.conceptExplanation != null)
            Builder(builder: (context) {
              final info = _approachConceptInfo(session!);
              return _ExplanationCard(
                keywords: info.keywords,
                formulas: info.formulas,
                summary: info.summary,
                onListenToggle: () => _toggleSpeak(info.summary),
                isSpeaking: _isSpeaking,
                onKeywordTap: (kw) => _showKeywordPreviewAndMaybeStart(context, session!, kw),
                onDetailsPressed: () async {
                  final sub = context.read<SubscriptionProvider>();
                  if (!sub.canOpenDetails()) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.l10n.detailsDailyLimitReached)),
                    );
                    return;
                  }
                  sub.registerDetailsOpened();
                  await _showDetailsBottomSheet(context, session!);
                },
              );
            }),
          const SizedBox(height: 16),
          if (session?.conceptExplanation != null) _buildEvaluationCard(context, session!),
          const SizedBox(height: 16),
          if (session?.aiFeedback != null)
            _FeedbackCard(score: session!.initialScore, feedback: session.aiFeedback!),
          if (session?.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                session!.errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 24),
          if (session?.conceptExplanation != null)
            FilledButton(
              onPressed: () async {
                await session!.commitLesson();
                if (mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.lessonSaveAndReturn),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, LessonSessionProvider? session) {
    final l10n = context.l10n;
    final stage = session?.stage ?? LessonStage.idle;
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
              onChanged: (v) {
                if (session != null) _handlePromptChanged(v, session);
              },
            ),
            if (session?.isAnalyzingConcepts == true)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
            if ((session?.isAnalyzingConcepts ?? false) == false && (session?.conceptBreakdown.isNotEmpty ?? false))
              _buildConceptHelper(context, session!),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('난이도:'),
                Expanded(
                  child: Slider(
                    value: _selectedDifficulty.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '단계 $_selectedDifficulty',
                    onChanged: stage == LessonStage.generatingContent || stage == LessonStage.evaluating
                        ? null
                        : (value) {
                            final v = value.round();
                            if (v != _selectedDifficulty) {
                              setState(() => _selectedDifficulty = v);
                              // 난이도 변경 시 이전 생성물 초기화
                              session?.reset();
                              session?.clearConceptSuggestions();
                            }
                          },
                  ),
                ),
                Text('단계 $_selectedDifficulty'),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: (stage == LessonStage.generatingContent || stage == LessonStage.evaluating || session == null)
                  ? null
                  : () async {
                      final raw = _topicController.text.trim();
                      if (raw.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.lessonEnterTopicFirst)),
                        );
                        return;
                      }
                      await _startLessonWithTopic(context, session, raw);
                    },
              icon: const Icon(Icons.auto_awesome),
              label: Text(l10n.lessonGenerate),
            ),
            if (stage == LessonStage.generatingContent)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildConceptHelper(BuildContext context, LessonSessionProvider session) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final conceptChips = session.conceptBreakdown
        .map(
          (concept) => ChoiceChip(
            label: Text(concept.name),
            selected: session.selectedConcept == concept,
            onSelected: (selected) async {
              if (selected) {
                session.selectConcept(concept);
                await _showKeywordPreviewAndMaybeStart(context, session, concept.name);
              } else {
                session.deselectConcept();
              }
            },
          ),
        )
        .toList();
    final explanation = session.selectedConcept?.summary.trim().isNotEmpty == true
        ? session.selectedConcept!.summary.trim()
        : l10n.lessonConceptNoSelection;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.lessonConceptExplanationTitle, style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(cleanMathForDisplay(explanation), style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard(BuildContext context, LessonSessionProvider session) {
    final l10n = context.l10n;
    final stage = session.stage;
    final speech = context.read<SpeechService>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.lessonExplainBack, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(labelText: l10n.lessonYourExplanation),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
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
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.lessonVoiceUnavailable)),
                              );
                            }
                          }
                        },
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  label: Text(_isListening ? l10n.lessonListening : l10n.lessonSpeakExplanation),
                ),
              ],
            ),
            if (stage == LessonStage.evaluating)
              const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
          ],
        ),
      ),
    );
  }

  // --- Actions ---
  void _handlePromptChanged(String value, LessonSessionProvider session) {
    final trimmed = value.trim();
    if (trimmed.length >= 6) {
      session.analyzeProblem(trimmed);
    } else if (session.conceptBreakdown.isNotEmpty || session.isAnalyzingConcepts) {
      session.clearConceptSuggestions();
    }
  }

  Future<void> _startLessonWithTopic(BuildContext context, LessonSessionProvider session, String topic, {bool countTowardsQuota = true}) async {
    if (session.stage == LessonStage.generatingContent || session.stage == LessonStage.evaluating) return;

    final trimmedTopic = topic.trim();
    final l10n = context.l10n;
    if (trimmedTopic.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.lessonEnterTopicFirst)));
      return;
    }
    final subscription = context.read<SubscriptionProvider>();
    // 무료 카운트는 "새로운 주제로 수업 만들기"일 때만 감소
    final isSameTopicAsLast = _lastCountedTopic != null && _lastCountedTopic == trimmedTopic;
    final willCount = countTowardsQuota && !isSameTopicAsLast;
    if (willCount && !subscription.canAskNewQuestion()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.lessonDailyLimitReached)));
      return;
    }
    final auth = context.read<AuthProvider>();
    FocusScope.of(context).unfocus();
    // reset UI/session state so new topic is clear
    try { await context.read<SpeechService>().stopSpeaking(); } catch (_) {}
    if (mounted) setState(() => _isSpeaking = false);
    _explanationController.clear();
    session.reset();
    await session.startLesson(
      topic: trimmedTopic,
      difficulty: _aiDifficulty,
      learnerName: auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    if (willCount) {
      subscription.registerQuestionAsked();
      _lastCountedTopic = trimmedTopic;
    }
    _topicController.text = trimmedTopic;
    // analyze for approach concepts so chips show under explanation automatically
    if (trimmedTopic.length >= 2) {
      session.analyzeProblem(trimmedTopic);
    }
  }

  Future<void> _toggleSpeak(String content) async {
    final speech = context.read<SpeechService>();
    if (_isSpeaking) {
      await speech.stopSpeaking();
      if (mounted) setState(() => _isSpeaking = false);
      return;
    }
    setState(() => _isSpeaking = true);
    speech.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    await speech.speakWithAgeAppropriateVoice(content, _aiDifficulty);
  }

  /// 접근 개념 카드에 필요한 정보(키워드, 공식, 설명)를 모두 반환
  ({List<String> keywords, List<String> formulas, String summary}) _approachConceptInfo(LessonSessionProvider session) {
    final raw = session.conceptExplanation ?? '';
    final text = cleanMathForDisplay(raw).trim();
    final topic = (session.topic ?? '').trim();
    final concepts = session.conceptBreakdown.map((e) => e.name.trim()).where((e) => e.isNotEmpty).toList();
    final topConcepts = concepts.take(3).toList();
    final formulas = _extractFormulaHints(topic, text);

    bool looksLikeProblem() {
      final t = topic.toLowerCase();
      if (RegExp(r'[=<>]|\\w|\d+').hasMatch(t)) return true;
      if (t.contains('?') || t.contains('구하시오') || t.contains('문제')) return true;
      return false;
    }
    String concise(String s, {int lines = 5, int chars = 300}) {
      var out = s.trim();
      final ls = out.split('\n');
      if (ls.length > lines) out = ls.take(lines).join('\n');
      if (out.length > chars) out = out.substring(0, chars) + '…';
      return out;
    }
    String summary;
    if (looksLikeProblem()) {
      final header = topConcepts.isNotEmpty
          ? '이 문제는 ' + topConcepts.join(', ') + ' 개념으로 접근하는 게 좋아요.'
          : '이 문제에 적합한 개념을 먼저 파악해볼게요.';
      summary = header + '\n\n자세한 개념 정리와 단계별 풀이는 [더 자세히 보기]에서 확인해요.';
    } else {
      final short = concise(text, lines: 2, chars: 180);
      summary = short.isEmpty
          ? '이 개념을 간단히 살펴봤어요. 예제와 함께 더 자세히 배우려면 [더 자세히 보기]를 눌러요.'
          : short + '\n\n예제와 함께 더 자세히 배우려면 [더 자세히 보기]를 눌러요.';
    }
    return (keywords: topConcepts, formulas: formulas, summary: summary);
  }

  // Heuristic formula name extraction from topic/explanation
  List<String> _extractFormulaHints(String topic, String explanation) {
    final src = (topic + '\n' + explanation).toLowerCase();
    final results = <String>{};

    bool hasAny(Iterable<String> words) => words.any((w) => src.contains(w));

    if (hasAny(['내분점', 'section formula'])) {
      results.add('내분점 공식');
    }
    if ((src.contains('등비수열') && hasAny(['합', '부분합', 'sn', 's_n'])) || hasAny(['sum of geometric series'])) {
      results.add('등비수열 합 공식');
    }
    if ((src.contains('등차수열') && hasAny(['합', '부분합', 'sn', 's_n'])) || hasAny(['sum of arithmetic series'])) {
      results.add('등차수열 합 공식');
    }
    if (hasAny(['근의 공식', 'quadratic formula', '2차방정식', '이차방정식'])) {
      results.add('이차방정식 근의 공식');
    }
    if (hasAny(['피타고라스', 'pythagorean'])) {
      results.add('피타고라스 정리');
    }
    if (src.contains('로그') && hasAny(['법칙', '성질', 'laws'])) {
      results.add('로그 법칙');
    }
    if (hasAny(['직선의 방정식']) || (hasAny(['y=','y =','기울기','절편','직선']) && !src.contains('원'))) {
      results.add('직선의 방정식');
    }
    // Cap to at most 2 hints to keep it concise
    return results.take(2).toList();
  }

  // --- Keyword preview/confirm ---
  Future<void> _showKeywordPreviewAndMaybeStart(
    BuildContext context,
    LessonSessionProvider session,
    String keyword,
  ) async {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    String? preview;
    bool loading = true;
    bool startedFetch = false;
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          // kick off fetch once
          if (!startedFetch) {
            startedFetch = true;
            () async {
              final text = await _buildBriefSummaryForKeyword(context, keyword, session);
              if (!ctx.mounted) return;
              setState(() {
                preview = text;
                loading = false;
              });
            }();
          }

          bool isSpeaking = false;
          final speech = context.read<SpeechService>();
          speech.setCompletionHandler(() {
            if (ctx.mounted) {
              (ctx as Element).markNeedsBuild();
              isSpeaking = false;
            }
          });

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text('# $keyword', style: theme.textTheme.titleMedium)),
                      IconButton(
                        onPressed: loading
                            ? null
                            : () async {
                                if (isSpeaking) {
                                  await speech.stopSpeaking();
                                  isSpeaking = false;
                                  if ((ctx as Element).mounted) (ctx).markNeedsBuild();
                                } else {
                                  isSpeaking = true;
                                  if ((ctx as Element).mounted) (ctx).markNeedsBuild();
                                  await speech.speakWithAgeAppropriateVoice(preview ?? '', _aiDifficulty);
                                }
                              },
                        icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up_outlined),
                        tooltip: isSpeaking ? l10n.lessonStopSpeaking : l10n.lessonListen,
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (loading) ...[
                    Row(children: const [
                      SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 12),
                      Text('불러오는 중...'),
                    ]),
                  ] else ...[
                    Text(preview ?? '', style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        await speech.stopSpeaking();
                        if (ctx.mounted) Navigator.of(ctx).pop();
                        if (mounted) {
                          await _startLessonWithTopic(
                            context,
                            session,
                            keyword,
                            countTowardsQuota: false,
                          );
                        }
                      },
                      child: const Text('이 개념으로 새 수업 시작'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Future<String> _buildBriefSummaryForKeyword(
    BuildContext context,
    String keyword,
    LessonSessionProvider session,
  ) async {
    String summary = session.conceptBreakdown
        .firstWhere((c) => c.name.trim() == keyword.trim(), orElse: () => const ConceptBreakdown(name: '', summary: ''))
        .summary
        .trim();
    summary = summary.isNotEmpty
        ? summary
        : (session.conceptBreakdown
                .firstWhere(
                  (c) => c.name.trim().toLowerCase().contains(keyword.trim().toLowerCase()),
                  orElse: () => const ConceptBreakdown(name: '', summary: ''),
                )
                .summary
                .trim());
    if (summary.isEmpty) {
      final ai = context.read<AiContentService>();
      final auth = context.read<AuthProvider>();
      final learner = auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback;
      final text = await ai.explainConcept(topic: keyword, difficulty: _aiDifficulty, learnerName: learner);
      summary = text.trim();
    }
    String trimmed = summary;
    if (trimmed.length > 240) trimmed = '${trimmed.substring(0, 240)}…';
    final lines = trimmed.split('\n');
    if (lines.length > 4) trimmed = lines.take(4).join('\n');
    return cleanMathForDisplay(trimmed);
  }

  Future<void> _showDetailsBottomSheet(BuildContext context, LessonSessionProvider session) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final explanation = session.conceptExplanation ?? '';
    // 초기 내용: 기존 설명 일부만 바로 표시
    String base = explanation;
    if (base.length > 600) base = '${base.substring(0, 600)}…';
    base = cleanMathForDisplay(base);

    if (!mounted) return;
    String displayed = base;
    bool loading = true;
    bool startedFetch = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          // 한번만 비동기 보충 설명 요청
          if (!startedFetch) {
            startedFetch = true;
            () async {
              try {
                final ai = context.read<AiContentService>();
                final auth = context.read<AuthProvider>();
                final learner = auth.currentUser?.displayName ?? l10n.generalLearnerFallback;
                final topic = session.topic ?? session.selectedConcept?.name ?? '수학 개념';
                // Problem vs concept-tailored prompting via service topic text
                // Here we assume ai.explainConcept respects difficulty and learner, and varies by topic phrasing
                final isProblem = RegExp(r'[=<>]|\\\w|\d+|\?|구하시오|문제').hasMatch(topic.toLowerCase());
                final richTopic = isProblem
                    ? '$topic (접근 개념과 풀이 과정을 단계별로 자세히 설명하고, 필요한 수학적 개념을 먼저 제시해 주세요)'
                    : '$topic (간단한 정의 요약 후, 예제 중심으로 자세히 설명해 주세요)';
                final supplement = await ai.explainConcept(
                  topic: richTopic,
                  difficulty: _aiDifficulty,
                  learnerName: learner,
                );
                if (!ctx.mounted) return;
                if (supplement.trim().isNotEmpty) {
                  setState(() {
                    displayed = '$displayed\n\n${cleanMathForDisplay(supplement)}';
                    loading = false;
                  });
                  // 상세 내용을 세션에 저장하여, 저장 시에만 영구 보관되도록 함
                  try {
                    context.read<LessonSessionProvider>().setDetailedExplanation(displayed);
                  } catch (_) {}
                } else {
                  setState(() => loading = false);
                }
              } catch (_) {
                if (ctx.mounted) setState(() => loading = false);
              }
            }();
          }

          // 키워드는 현재 표시 중인 텍스트에서 추출
          List<String> keywords = session.conceptBreakdown.map((e) => e.name).where((s) => s.trim().isNotEmpty).take(8).toList();
          if (keywords.isEmpty && displayed.trim().isNotEmpty) {
            final text = displayed.toLowerCase();
            const candidates = [
              '등비수열','등차수열','수열','등비','등차','부분합','합','첫째항','공비','공차','항',
              '기하수열','산술수열','등비급수','등차급수',
              '함수','미분','적분','극한','로그','지수','확률','통계','그래프','좌표','기울기','절편',
              'geometric sequence','geometric series','arithmetic sequence','arithmetic series',
              'partial sum','first term','common ratio','common difference',
            ];
            final set = <String>{};
            for (final c in candidates) {
              if (text.contains(c.toLowerCase())) set.add(c);
            }
            keywords = set.take(8).toList();
          }

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('더 자세히 보기', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (keywords.isNotEmpty) ...[
                      Text('관련 개념으로 다시 배워 보기', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final kw in keywords)
                            ActionChip(
                              label: Text('# $kw'),
                              onPressed: () async {
                                if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
                                if (mounted) {
                                  await _showKeywordPreviewAndMaybeStart(context, session, kw);
                                }
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(displayed, style: theme.textTheme.bodyMedium),
                    if (loading) ...[
                      const SizedBox(height: 12),
                      Row(children: const [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text('내용 불러오는 중...'),
                      ]),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                        label: Text(l10n.generalClose),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }
}

// (no extra helpers; using cleanMathForDisplay from core/utils/math_text.dart)

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.keywords,
    required this.formulas,
    required this.summary,
    required this.onListenToggle,
    required this.isSpeaking,
    required this.onKeywordTap,
    this.onDetailsPressed,
  });

  final List<String> keywords;
  final List<String> formulas;
  final String summary;
  final VoidCallback onListenToggle;
  final bool isSpeaking;
  final void Function(String keyword) onKeywordTap;
  final VoidCallback? onDetailsPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(l10n.lessonExplanationTitle, style: Theme.of(context).textTheme.titleMedium)),
                OutlinedButton.icon(
                  onPressed: onListenToggle,
                  icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up_outlined),
                  label: Text(isSpeaking ? l10n.lessonStopSpeaking : l10n.lessonListen),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (keywords.isNotEmpty) ...[
              Text('관련 개념으로 다시 배워 보기', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
            if (formulas.isNotEmpty) ...[
              Text('• 공식: ${formulas.join(', ')}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
            ],
            Text(summary),
            if (onDetailsPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: onDetailsPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(context.l10n.lessonShowMoreDetail),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(spacing: 8, children: [
              Chip(label: Text(l10n.lessonUnderstandingLabel(scoreLabel)), avatar: const Icon(Icons.assessment_outlined)),
            ]),
            const SizedBox(height: 12),
            Text(cleanMathForDisplay(feedback)),
          ],
        ),
      ),
    );
  }
}

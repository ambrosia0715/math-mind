import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _topicController = TextEditingController();
  final _explanationController = TextEditingController();
  int _selectedAge = 12;
  bool _isListening = false;

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
      age: _selectedAge,
      learnerName:
          auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    subscription.registerQuestionAsked();
    session.clearConceptSuggestions();
    if (!mounted) return;
    setState(() {
      _topicController.text = trimmedTopic;
    });
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
            _ExplanationCard(content: session.conceptExplanation!),
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
                Text(l10n.lessonTargetAge),
                Expanded(
                  child: Slider(
                    value: _selectedAge.toDouble(),
                    min: 5,
                    max: 19,
                    divisions: 14,
                    label: l10n.lessonAgeLabel(_selectedAge),
                    onChanged:
                        stage == LessonStage.generatingContent ||
                            stage == LessonStage.evaluating
                        ? null
                        : (value) {
                            final newAge = value.round();
                            if (newAge != _selectedAge) {
                              _resetGeneratedContent(session);
                              setState(() => _selectedAge = newAge);
                            }
                          },
                  ),
                ),
                Text(l10n.lessonAgeLabel(_selectedAge)),
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
                      : () => _startLessonWithTopic(
                          context,
                          session,
                          _topicController.text,
                        ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.lessonGenerate),
                ),
                OutlinedButton.icon(
                  onPressed: session.conceptExplanation == null
                      ? null
                      : () async {
                          final content = session.conceptExplanation!;
                          await speech.speak(content);
                        },
                  icon: const Icon(Icons.volume_up_outlined),
                  label: Text(l10n.lessonListen),
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
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: l10n.lessonYourExplanation,
              ),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Row(
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
                const SizedBox(width: 12),
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
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({required this.content});

  final String content;

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
            Text(content),
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
            Text(feedback),
          ],
        ),
      ),
    );
  }
}

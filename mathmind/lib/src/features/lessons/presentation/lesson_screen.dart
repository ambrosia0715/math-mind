import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/speech_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _topicController = TextEditingController();
  final _problemController = TextEditingController();
  final _explanationController = TextEditingController();
  int _selectedGrade = 5;
  bool _isListening = false;

  @override
  void dispose() {
    _topicController.dispose();
    _problemController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<LessonSessionProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Adaptive lesson')),
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
              child: const Text('Save lesson & return'),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, LessonSessionProvider session) {
    final auth = context.read<AuthProvider>();
    final subscription = context.read<SubscriptionProvider>();
    final speech = context.read<SpeechService>();
    final stage = session.stage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tell MathMind what to learn',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Math topic or concept',
                hintText: 'e.g. Fractions addition',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Target grade:'),
                Expanded(
                  child: Slider(
                    value: _selectedGrade.toDouble(),
                    min: 1,
                    max: 12,
                    divisions: 11,
                    label: 'Grade $_selectedGrade',
                    onChanged: stage == LessonStage.generatingContent
                        ? null
                        : (value) =>
                              setState(() => _selectedGrade = value.round()),
                  ),
                ),
                Text('$_selectedGrade'),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: stage == LessonStage.generatingContent
                      ? null
                      : () async {
                          if (!subscription.canAskNewQuestion()) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Daily question limit reached.'),
                              ),
                            );
                            return;
                          }
                          final topic = _topicController.text.trim();
                          if (topic.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Enter a topic first.'),
                              ),
                            );
                            return;
                          }
                          await session.startLesson(
                            topic: topic,
                            grade: _selectedGrade,
                            learnerName:
                                auth.currentUser?.displayName ?? 'Learner',
                          );
                          subscription.registerQuestionAsked();
                          _problemController.clear();
                        },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Generate lesson'),
                ),
                OutlinedButton.icon(
                  onPressed: session.conceptExplanation == null
                      ? null
                      : () async {
                          final content = session.conceptExplanation!;
                          await speech.speak(content);
                        },
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Listen'),
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

  Widget _buildEvaluationCard(
    BuildContext context,
    LessonSessionProvider session,
  ) {
    final speech = context.read<SpeechService>();
    final stage = session.stage;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Explain the concept back to MathMind',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _problemController,
              decoration: const InputDecoration(
                labelText: 'Optional: paste a question you are working on',
              ),
              minLines: 1,
              maxLines: 3,
              onChanged: (value) {
                if (value.trim().length > 10) {
                  session.analyzeProblem(value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationController,
              decoration: const InputDecoration(labelText: 'Your explanation'),
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
                              const SnackBar(
                                content: Text('Share your explanation first.'),
                              ),
                            );
                            return;
                          }
                          await session.evaluateUnderstanding(explanation);
                        },
                  icon: const Icon(Icons.analytics_outlined),
                  label: const Text('Evaluate understanding'),
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
                                const SnackBar(
                                  content: Text('Voice capture not available.'),
                                ),
                              );
                            }
                          }
                        },
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  label: Text(
                    _isListening ? 'Listening...' : 'Speak explanation',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MathMind explanation',
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
    final chips = <Widget>[
      Chip(
        label: Text('Understanding: ${score ?? '-'}'),
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

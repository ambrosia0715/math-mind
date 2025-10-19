import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/lesson_history_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/application/auth_provider.dart';
import '../../lessons/domain/lesson_history.dart';

class LessonReviewScreen extends StatefulWidget {
  const LessonReviewScreen({super.key, required this.lesson});

  static const routeName = '/lesson-review';

  final LessonHistory lesson;

  @override
  State<LessonReviewScreen> createState() => _LessonReviewScreenState();
}

class _LessonReviewScreenState extends State<LessonReviewScreen> {
  late LessonHistory _lesson;
  String? _explanation;
  bool _isRegenerating = false;
  String? _regenerateError;

  @override
  void initState() {
    super.initState();
    _lesson = widget.lesson;
    _explanation = _lesson.conceptExplanation?.trim();
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
    final retentionScoreLabel = _lesson.retentionScore != null
        ? '${_lesson.retentionScore}'
        : l10n.reviewRetentionPending;

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
                  Text(
                    l10n.reviewRetentionScore(retentionScoreLabel),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
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
                    SelectableText(_explanation!)
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
    super.dispose();
  }
}

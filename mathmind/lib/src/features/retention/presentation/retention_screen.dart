import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lessons/domain/lesson_history.dart';
import '../../lessons/presentation/lesson_review_screen.dart';
import '../application/retention_provider.dart';
import '../../../l10n/app_localizations.dart';

enum RetentionFilter { all, pendingOnly, progressedOnly }

class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key, this.filter = RetentionFilter.all});

  static const routeName = '/retention';
  final RetentionFilter filter;

  @override
  Widget build(BuildContext context) {
    final retention = context.watch<RetentionProvider>();
    // Apply filter based on lastRetentionScore threshold (>= 30 is progressed)
    final all = retention.dueLessons;
    final lessons = () {
      switch (filter) {
        case RetentionFilter.pendingOnly:
          return all.where((l) => (l.lastRetentionScore ?? -1) < 30).toList();
        case RetentionFilter.progressedOnly:
          return all.where((l) => (l.lastRetentionScore ?? -1) >= 30).toList();
        case RetentionFilter.all:
          return all;
      }
    }();
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.retentionAppBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: retention.isLoading
            ? const Center(child: CircularProgressIndicator())
            : lessons.isEmpty
            ? Center(child: Text(l10n.retentionEmptyMessage))
            : ListView.separated(
                itemBuilder: (context, index) {
                  final lesson = lessons[index];
                  return _RetentionTaskCard(lesson: lesson);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: lessons.length,
              ),
      ),
    );
  }
}

class _RetentionTaskCard extends StatefulWidget {
  const _RetentionTaskCard({required this.lesson});

  final LessonHistory lesson;

  @override
  State<_RetentionTaskCard> createState() => _RetentionTaskCardState();
}

class _RetentionTaskCardState extends State<_RetentionTaskCard> {
  _RetentionTaskCardState();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final learnedDate =
        widget.lesson.learnedAt?.toLocal().toString().split(' ').first ?? '-';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.lesson.topic,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.retentionLearnedDate(learnedDate)),
            if (widget.lesson.detectedConcept != null &&
                widget.lesson.detectedConcept!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  l10n.retentionConcept(widget.lesson.detectedConcept!),
                ),
              ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LessonReviewScreen(
                      lesson: widget.lesson,
                      startWithBlankExplanation: true,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.retentionOpenLesson),
            ),
            const SizedBox(height: 8),
            if (widget.lesson.initialScore != null)
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      context.l10n.lessonUnderstandingLabel(
                        widget.lesson.initialScore!.toString(),
                      ),
                    ),
                    avatar: const Icon(Icons.assessment_outlined),
                  ),
                ],
              )
            else
              Text(
                context.l10n.homeRetentionPending,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

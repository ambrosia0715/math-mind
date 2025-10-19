import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lessons/domain/lesson_history.dart';
import '../../lessons/presentation/lesson_review_screen.dart';
import '../application/retention_provider.dart';
import '../../../l10n/app_localizations.dart';

class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key});

  static const routeName = '/retention';

  @override
  Widget build(BuildContext context) {
    final retention = context.watch<RetentionProvider>();
    final lessons = retention.dueLessons;
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
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.lesson.retentionScore?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
                    builder: (_) => LessonReviewScreen(lesson: widget.lesson),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: Text(l10n.retentionOpenLesson),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: l10n.retentionScoreLabel),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        final raw = int.tryParse(_controller.text);
                        if (raw == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.retentionScoreError)),
                          );
                          return;
                        }
                        setState(() => _submitting = true);
                        await context
                            .read<RetentionProvider>()
                            .markRetentionComplete(
                              widget.lesson,
                              raw.clamp(0, 100),
                            );
                        if (mounted) {
                          setState(() => _submitting = false);
                        }
                      },
                child: Text(
                  _submitting ? l10n.retentionSaving : l10n.retentionSaveButton,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../lessons/domain/lesson_history.dart';
import '../application/retention_provider.dart';

class RetentionScreen extends StatelessWidget {
  const RetentionScreen({super.key});

  static const routeName = '/retention';

  @override
  Widget build(BuildContext context) {
    final retention = context.watch<RetentionProvider>();
    final lessons = retention.dueLessons;

    return Scaffold(
      appBar: AppBar(title: const Text('Retention review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: retention.isLoading
            ? const Center(child: CircularProgressIndicator())
            : lessons.isEmpty
            ? const Center(child: Text('No reviews due today. Keep learning!'))
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
            Text(
              'Learned: ${widget.lesson.learnedAt?.toLocal().toString().split(' ').first ?? '-'}',
            ),
            if (widget.lesson.detectedConcept != null &&
                widget.lesson.detectedConcept!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Concept: ${widget.lesson.detectedConcept}'),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Retention score (0 - 100)',
              ),
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
                            const SnackBar(
                              content: Text('Enter a score between 0 and 100.'),
                            ),
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
                child: Text(_submitting ? 'Saving...' : 'Save retention score'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

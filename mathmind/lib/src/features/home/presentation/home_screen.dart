import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/lesson_history_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../lessons/domain/lesson_history.dart';
import '../../lessons/presentation/lesson_screen_clean.dart';
import '../../lessons/presentation/lesson_review_screen.dart';
import '../../retention/application/retention_provider.dart';
import '../../retention/presentation/retention_screen.dart';
import '../../subscription/application/subscription_provider.dart';
import '../../subscription/domain/subscription_plan.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/mathmind_logo.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final retention = context.watch<RetentionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const MathMindLogo(height: 28),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SubscriptionProvider>().loadOfferings();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _LearningOverview(
              subscription: subscription,
              retentionTotal: retention.dueLessons.length,
              retentionProgressed: retention.progressedCount,
            ),
            const SizedBox(height: 24),
            _ActionButtons(subscription: subscription),
            const SizedBox(height: 24),
            const _LessonHistoryPanel(),
          ],
        ),
      ),
    );
  }
}

class _LearningOverview extends StatelessWidget {
  const _LearningOverview({
    required this.subscription,
    required this.retentionTotal,
    required this.retentionProgressed,
  });

  final SubscriptionProvider subscription;
  final int retentionTotal;
  final int retentionProgressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierLabel = subscription.activeTier.name.toUpperCase();
    final remaining = subscription.remainingDailyQuestions;
    final l10n = context.l10n;
    final remainingLabel = subscription.activeTier == SubscriptionTier.free
        ? (remaining != null ? '$remaining' : l10n.homeDailyLimitLoading)
        : l10n.generalUnlimited;
    final pending = (retentionTotal - retentionProgressed).clamp(0, retentionTotal);
    final retentionSummary = l10n.homeRetentionSummary(
      retentionTotal.toString(),
      retentionProgressed.toString(),
      pending.toString(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.homeWelcomeBack, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.homeCurrentPlan(tierLabel),
              style: theme.textTheme.bodyMedium,
            ),
            if (subscription.activeTier == SubscriptionTier.free)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.homeFreePlanDescription,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _PillStatistic(
                  icon: Icons.chat_bubble_outline,
                  label: l10n.homeQuestionsLeft,
                  value: remainingLabel,
                ),
                const SizedBox(width: 12),
                _PillStatistic(
                  icon: Icons.timer_outlined,
                  label: l10n.homeRetentionDue,
                  value: retentionSummary,
                  trailingButtons: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RetentionScreen(
                              filter: RetentionFilter.pendingOnly,
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.homeViewPendingReviews),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RetentionScreen(
                              filter: RetentionFilter.progressedOnly,
                            ),
                          ),
                        );
                      },
                      child: Text(l10n.homeViewProgressedReviews),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillStatistic extends StatelessWidget {
  const _PillStatistic({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingButtons = const <Widget>[],
  });

  final IconData icon;
  final String label;
  final String value;
  final List<Widget> trailingButtons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.titleMedium,
                ),
                if (trailingButtons.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: trailingButtons),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.subscription});

  final SubscriptionProvider subscription;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = subscription.isDailyLimitReady;
    final canAsk = subscription.canAskNewQuestion();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: canAsk
              ? () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LessonScreen(),
                    ),
                  );
                }
              : null,
          icon: const Icon(Icons.auto_stories),
          label: Text(l10n.homeStartAdaptiveLesson),
        ),
        if (!canAsk)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              isReady
                  ? l10n.homeDailyLimitReachedUpgrade
                  : l10n.homeDailyLimitLoading,
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LessonHistoryPanel extends StatelessWidget {
  const _LessonHistoryPanel();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) {
      return const SizedBox.shrink();
    }

    final historyService = context.read<LessonHistoryService>();
    final l10n = context.l10n;

    return StreamBuilder<List<LessonHistory>>(
      stream: historyService.watchByUser(auth.currentUser!.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final lessons = snapshot.data ?? [];
        if (lessons.isEmpty) {
          return Text(l10n.homeNoLessonsYet);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.homeRecentLessons,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            for (final lesson in lessons.take(5))
              Card(
                child: ListTile(
                  leading: const Icon(Icons.bookmark_added_outlined),
                  title: Text(lesson.topic),
                  subtitle: Text(_buildLessonSubtitle(context, lesson)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LessonReviewScreen(lesson: lesson),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  String _buildLessonSubtitle(BuildContext context, LessonHistory lesson) {
    final l10n = context.l10n;
    final score = lesson.initialScore != null ? '${lesson.initialScore}' : '-';
    final due = lesson.reviewDue != null
        ? lesson.reviewDue!.toLocal().toString().split(' ').first
        : l10n.homeLessonReviewCompleted;
    return l10n.homeLessonSummary(score, due);
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/lesson_history_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../lessons/application/lesson_session_provider.dart';
import '../../lessons/domain/lesson_history.dart';
import '../../lessons/presentation/lesson_screen.dart';
import '../../retention/application/retention_provider.dart';
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
              retentionCount: retention.dueLessons.length,
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
    required this.retentionCount,
  });

  final SubscriptionProvider subscription;
  final int retentionCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tierLabel = subscription.activeTier.name.toUpperCase();
    final remaining = subscription.remainingDailyQuestions;
    final l10n = context.l10n;

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
                  value: subscription.activeTier == SubscriptionTier.free
                      ? '${remaining ?? 0}'
                      : l10n.generalUnlimited,
                ),
                const SizedBox(width: 12),
                _PillStatistic(
                  icon: Icons.timer_outlined,
                  label: l10n.homeRetentionDue,
                  value: retentionCount.toString(),
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
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
    final sessionProvider = context.watch<LessonSessionProvider>();
    final theme = Theme.of(context);
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
              l10n.homeDailyLimitReachedUpgrade,
              style: theme.textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
        if (subscription.hasPremiumAccess)
          OutlinedButton.icon(
            onPressed: sessionProvider.detectedConcept == null
                ? null
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.homeVisualExplanationSoon)),
                    );
                  },
            icon: const Icon(Icons.image_outlined),
            label: Text(l10n.homeOpenVisualExplanation),
          )
        else
          TextButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                builder: (_) => const _UpgradeSheet(),
              );
            },
            child: Text(
              l10n.homeUpgradeForVisual,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet();

  @override
  Widget build(BuildContext context) {
    final subscription = context.watch<SubscriptionProvider>();
    final offerings = subscription.offerings;
    final packages = offerings?.current?.availablePackages ?? [];
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.homeUpgradeTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.homeUpgradeBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (packages.isEmpty)
            Text(l10n.homePlansLoading)
          else
            for (final package in packages)
              ListTile(
                title: Text(package.storeProduct.title),
                subtitle: Text(package.storeProduct.description),
                trailing: Text(package.storeProduct.priceString),
                onTap: () async {
                  await context.read<SubscriptionProvider>().purchasePlan(
                    package,
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
        ],
      ),
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

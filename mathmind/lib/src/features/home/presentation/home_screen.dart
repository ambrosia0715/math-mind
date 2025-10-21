import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/lesson_history_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../lessons/domain/lesson_history.dart';
import '../../lessons/presentation/lesson_screen.dart' show LessonScreen;
import '../../lessons/presentation/lesson_review_screen.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const MathMindLogo(height: 32),
        centerTitle: false,
        actions: [
          // 학습 진도 간단 표시
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department_outlined,
                      size: 16,
                      color: Color(0xFF2C3E85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${retention.dueLessons.length}개 복습 대기',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2C3E85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<SubscriptionProvider>().loadOfferings();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            _LearningOverview(
              subscription: subscription,
              retentionTotal: retention.dueLessons.length,
              retentionProgressed: retention.progressedCount,
            ),
            const SizedBox(height: 28),
            _ActionButtons(subscription: subscription),
            const SizedBox(height: 28),
            const _RecentLessonsPanel(),
            const SizedBox(height: 24),
            const _ReviewHistoryPanel(),
            const SizedBox(height: 20),
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
    final tierLabel = subscription.activeTier.name.toUpperCase();
    final remaining = subscription.remainingDailyQuestions;
    final l10n = context.l10n;
    final remainingLabel = subscription.activeTier == SubscriptionTier.free
        ? (remaining != null ? '$remaining' : l10n.homeDailyLimitLoading)
        : l10n.generalUnlimited;
    final pending = (retentionTotal - retentionProgressed).clamp(
      0,
      retentionTotal,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2C3E85), const Color(0xFF5B7FD4)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2C3E85).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환영 메시지
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.homeWelcomeBack,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '개념으로 이해하는 수학',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 구분선
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 통계 카드들
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.chat_bubble_outline,
                    label: '남은 질문',
                    value: remainingLabel,
                    isCompact: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.timer_outlined,
                    label: '복습 대기',
                    value: '$pending개',
                    isCompact: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 플랜 정보
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.homeCurrentPlan(tierLabel),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 새로운 통계 카드 위젯
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.isCompact = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: isCompact ? 20 : 24,
            color: Colors.white.withOpacity(0.9),
          ),
          SizedBox(height: isCompact ? 8 : 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isCompact ? 11 : 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.subscription});

  final SubscriptionProvider subscription;

  @override
  Widget build(BuildContext context) {
    final isReady = subscription.isDailyLimitReady;
    final canAsk = subscription.canAskNewQuestion();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C3E85),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                '학습 시작하기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
            ],
          ),
        ),

        // 메인 버튼
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: canAsk
                ? const LinearGradient(
                    colors: [Color(0xFF2C3E85), Color(0xFF5B7FD4)],
                  )
                : null,
            color: canAsk ? null : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(14),
            boxShadow: canAsk
                ? [
                    BoxShadow(
                      color: const Color(0xFF2C3E85).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canAsk
                  ? () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LessonScreen(),
                        ),
                      );
                    }
                  : null,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      color: canAsk ? Colors.white : const Color(0xFF9CA3AF),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '맞춤형 개념 학습 시작',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: canAsk ? Colors.white : const Color(0xFF9CA3AF),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (!canAsk)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Color(0xFFD97706),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isReady
                          ? l10n.homeDailyLimitReachedUpgrade
                          : l10n.homeDailyLimitLoading,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// 최근 수업 패널 (복습 시간이 아직 안 된 것들)
class _RecentLessonsPanel extends StatelessWidget {
  const _RecentLessonsPanel();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) {
      return const SizedBox.shrink();
    }

    final historyService = context.read<LessonHistoryService>();
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E85),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              l10n.homeRecentLessons,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 최근 학습 기록 리스트 (복습 시간 전)
        StreamBuilder<List<LessonHistory>>(
          stream: historyService.watchByUser(auth.currentUser!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final allLessons = snapshot.data ?? [];
            final now = DateTime.now();
            // 복습 시간이 아직 안 된 것들만 표시
            final recentLessons = allLessons
                .where(
                  (lesson) =>
                      lesson.reviewDue != null &&
                      lesson.reviewDue!.isAfter(now),
                )
                .toList();

            if (recentLessons.isEmpty) {
              return _EmptyStateCard(
                icon: Icons.auto_stories_outlined,
                iconColor: const Color(0xFF9CA3AF),
                iconBackgroundColor: const Color(0xFFF3F4F6),
                message: l10n.homeNoLessonsYet,
              );
            }

            return Column(
              children: [
                for (final lesson in recentLessons.take(5)) ...[
                  _LessonHistoryCard(lesson: lesson, isReviewMode: false),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

// 복습 패널 (복습 시간이 된 것들)
class _ReviewHistoryPanel extends StatelessWidget {
  const _ReviewHistoryPanel();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isSignedIn) {
      return const SizedBox.shrink();
    }

    final historyService = context.read<LessonHistoryService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              '복습',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 복습 대기 리스트
        StreamBuilder<List<LessonHistory>>(
          stream: historyService.watchByUser(auth.currentUser!.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final allLessons = snapshot.data ?? [];
            final now = DateTime.now();
            // 복습 시간이 된 것들만 표시
            final reviewLessons = allLessons
                .where(
                  (lesson) =>
                      lesson.reviewDue != null &&
                      !lesson.reviewDue!.isAfter(now),
                )
                .toList();

            if (reviewLessons.isEmpty) {
              return const _EmptyStateCard(
                icon: Icons.check_circle_outline,
                iconColor: Color(0xFFF59E0B),
                iconBackgroundColor: Color(0xFFFEF3C7),
                message: '복습할 내용이 없어요',
              );
            }

            return Column(
              children: [
                for (final lesson in reviewLessons.take(5)) ...[
                  _LessonHistoryCard(lesson: lesson, isReviewMode: true),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LessonHistoryCard extends StatelessWidget {
  const _LessonHistoryCard({required this.lesson, this.isReviewMode = false});

  final LessonHistory lesson;
  final bool isReviewMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => LessonReviewScreen(
                  lesson: lesson,
                  startWithBlankExplanation: isReviewMode,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 아이콘 (최근 수업 vs 복습)
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isReviewMode
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isReviewMode
                        ? Icons.schedule_outlined
                        : Icons.bookmark_added_outlined,
                    color: isReviewMode
                        ? const Color(0xFFF59E0B)
                        : const Color(0xFF2C3E85),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // 내용
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.topic,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (lesson.initialScore != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getScoreColor(
                                  lesson.initialScore!,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.assessment_outlined,
                                    size: 12,
                                    color: _getScoreColor(lesson.initialScore!),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${lesson.initialScore}점',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getScoreColor(
                                        lesson.initialScore!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (lesson.learnedAt != null)
                            Text(
                              _formatDate(lesson.learnedAt!),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 삭제 버튼
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  tooltip: '삭제',
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('학습 기록 삭제'),
                        content: Text('${lesson.topic}\n\n이 학습 기록을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('취소'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('삭제'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        final historyService = context
                            .read<LessonHistoryService>();
                        await historyService.delete(lesson.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('학습 기록이 삭제되었습니다')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
                        }
                      }
                    }
                  },
                ),

                // 화살표
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return const Color(0xFF10B981); // Green
    if (score >= 60) return const Color(0xFF3B82F6); // Blue
    if (score >= 40) return const Color(0xFFF59E0B); // Orange
    return const Color(0xFFEF4444); // Red
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '오늘';
    } else if (diff.inDays == 1) {
      return '어제';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}일 전';
    } else {
      return '${date.month}/${date.day}';
    }
  }
}

// 빈 상태 카드 (공통)
class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.message,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: iconColor),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const supportedLocales = [Locale('ko'), Locale('en')];

  static AppLocalizations of(BuildContext context) {
    final result = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(result != null, 'No AppLocalizations found in context');
    return result!;
  }

  bool get _isKorean => locale.languageCode == 'ko';

  // General / Navigation
  String get loadingApp => _isKorean ? 'MathMind 불러오는 중' : 'Loading MathMind';
  String get navLearn => _isKorean ? '학습' : 'Learn';
  String get navRetention => _isKorean ? '복습' : 'Retention';
  String get navProfile => _isKorean ? '프로필' : 'Profile';
  String get generalUnlimited => _isKorean ? '무제한' : 'Unlimited';
  String get generalLearnerFallback => _isKorean ? '학습자' : 'Learner';
  String get generalClose => _isKorean ? '닫기' : 'Close';

  // Home screen
  String get homeWelcomeBack => _isKorean ? '다시 만나서 반가워요!' : 'Welcome back!';
  String homeCurrentPlan(String tier) =>
      _isKorean ? '현재 이용권: $tier' : 'Current plan: $tier';
  String get homeFreePlanDescription => _isKorean
      ? '무료 플랜은 하루 100개의 AI 문제와 텍스트 설명을 제공해요.'
      : 'Free plan includes 100 AI questions per day with text explanations.';
  String get homeQuestionsLeft => _isKorean ? '남은 질문 수' : 'Questions left';
  String get homeRetentionDue => _isKorean ? '복습 예정 수' : 'Retention due';
    String homeRetentionSummary(String total, String progressed, String pending) =>
            _isKorean
                    ? '총 ${total}건 · 진행 ${progressed}건 · 미진행 ${pending}건'
                    : 'Total ${total} · progressed ${progressed} · pending ${pending}';
  String get homeViewPendingReviews => _isKorean ? '미진행만 보기' : 'View pending only';
  String get homeViewProgressedReviews =>
      _isKorean ? '진행한 것만 보기' : 'View progressed only';
  String get homeDailyLimitLoading =>
      _isKorean ? '남은 질문 수를 불러오는 중이에요...' : 'Loading...';
  String get homeStartAdaptiveLesson =>
      _isKorean ? '맞춤형 수업 시작' : 'Start adaptive lesson';
  String get homeDailyLimitReachedUpgrade => _isKorean
      ? '오늘의 질문 제한에 도달했어요. 계속 학습하려면 업그레이드하세요.'
      : 'Daily question limit reached. Upgrade to continue learning.';
  String get homeUpgradeForVisual => _isKorean
      ? '시각 설명을 이용하려면 업그레이드하세요'
      : 'Upgrade to unlock visual explanations';
  String get homeOpenVisualExplanation =>
      _isKorean ? '시각 설명 열기' : 'Open visual explanation';
  String get homeUpgradeTitle =>
      _isKorean ? '학습을 업그레이드하세요' : 'Upgrade your learning';
  String get homeUpgradeBody => _isKorean
      ? '프리미엄에서는 이미지 설명, 복습 관리, 학부모 리포트를 이용할 수 있어요.'
      : 'Premium adds image explanations, retention reviews, and parent reports.';
  String get homePlansLoading => _isKorean
      ? '플랜 정보를 불러오는 중이거나 아직 설정되지 않았어요.'
      : 'Plans are loading or not configured yet.';
  String get homeVisualExplanationSoon =>
      _isKorean ? '시각 설명 기능은 곧 제공될 예정이에요.' : 'Visual explanations coming soon.';
  String get homeNoLessonsYet => _isKorean
      ? '아직 학습 기록이 없어요. 지금 학습을 시작해 보세요!'
      : 'No lessons yet. Start learning to build your history!';
  String get homeRecentLessons => _isKorean ? '최근 학습' : 'Recent lessons';
  String get homeLessonReviewCompleted => _isKorean ? '완료' : 'completed';
  String homeLessonSummary(String score, String due) =>
      _isKorean ? '점수: $score · 복습: $due' : 'Score: $score · Review: $due';

  // Splash
  String get splashLoading =>
      _isKorean ? 'MathMind 불러오는 중' : 'Loading MathMind';

  // Dashboard navigation labels reuse nav getters

  // Lesson screen
  String get lessonAppBarTitle => _isKorean ? '맞춤형 수업' : 'Adaptive lesson';
  String get lessonSaveAndReturn =>
      _isKorean ? '학습을 저장하고 돌아가기' : 'Save lesson & return';
  String get lessonTellWhatToLearn =>
      _isKorean ? '배우고 싶은 내용을 알려 주세요' : 'Tell MathMind what to learn';
  String get lessonTopicLabel =>
      _isKorean ? '학습할 주제 또는 문제' : 'Topic or problem to learn';
  String get lessonTopicHint =>
      _isKorean ? '예: 분수 나누기 / 2x + 3 = 7' : 'e.g. Fractions or 2x + 3 = 7';
  String get lessonTargetAge => _isKorean ? '나이 선택:' : 'Select age:';
  String lessonAgeLabel(int age) => _isKorean ? '$age세' : '$age years old';
  String get lessonDailyLimitReached =>
      _isKorean ? '오늘의 질문 제한에 도달했어요.' : 'Daily question limit reached.';
  String get lessonEnterTopicFirst =>
      _isKorean ? '먼저 학습 주제를 입력해 주세요.' : 'Enter a topic first.';
  String get lessonTopicNeedsMath => _isKorean
      ? '수학 개념이나 문제를 입력해 줘. 예: 분수 나누기, 2x + 3 = 7'
      : 'Please enter a math concept or problem. e.g., Fractions or 2x + 3 = 7';
  String get lessonGenerate => _isKorean ? '수업 만들기' : 'Generate lesson';
  String get lessonListen => _isKorean ? '듣기' : 'Listen';
  String get lessonExplainBack => _isKorean
      ? 'MathMind에게 이해한 내용을 설명해 보세요'
      : 'Explain the concept back to MathMind';
  String get lessonConceptHelperTitle =>
      _isKorean ? '이 문제를 풀 때 필요한 개념' : 'Key concepts for this problem';
  String get lessonConceptHelperHint => _isKorean
      ? '개념을 고르면 그 주제로 바로 수업이 시작돼요.'
      : 'Select a concept to start a lesson on it.';
  String get lessonConceptExplanationTitle =>
      _isKorean ? '선택한 개념 설명' : 'Concept overview';
  String get lessonConceptNoSelection => _isKorean
      ? '개념을 선택하면 설명이 표시돼요.'
      : 'Pick a concept to view its explanation.';
  String get lessonYourExplanation => _isKorean ? '나의 설명' : 'Your explanation';
  String get lessonShareExplanationFirst =>
      _isKorean ? '먼저 설명을 입력해 주세요.' : 'Share your explanation first.';
  String get lessonEvaluateUnderstanding =>
      _isKorean ? '이해도 평가받기' : 'Evaluate understanding';
  String get lessonVoiceUnavailable =>
      _isKorean ? '음성 인식 기능을 사용할 수 없어요.' : 'Voice capture not available.';
  String get lessonListening => _isKorean ? '듣는 중...' : 'Listening...';
  String get lessonSpeakExplanation =>
      _isKorean ? '설명을 말해 주세요' : 'Speak explanation';
  String get lessonStopSpeaking => _isKorean ? '음성 중지' : 'Stop speaking';
  String get lessonExplanationTitle =>
      _isKorean ? '접근 개념' : 'Approach concepts';
  String get lessonShowMoreDetail =>
      _isKorean ? '더 자세히 보기' : 'View detailed explanation';
  String get detailsDailyLimitReached => _isKorean
      ? '오늘의 자세히 보기 제한에 도달했어요.'
      : 'Daily details limit reached.';
  String get lessonShowUnderstandingButton =>
      _isKorean ? '이해했는지 확인해 보기' : 'Check my understanding';
  String get lessonShowExplanationAgain =>
      _isKorean ? '설명 다시 보기' : 'View explanation again';
  String get lessonUnderstandingNotReady => _isKorean
      ? '먼저 MathMind에게 설명을 들려주고 이해도 평가를 받아 주세요.'
      : 'Share your explanation and evaluate it before checking understanding.';
  String get lessonUnderstandingLow => _isKorean
      ? '이해도가 아직 낮아요. 설명을 다시 읽고 함께 연습해 봐요!'
      : 'Your understanding score is low. Let us review the explanation together.';
  String lessonUnderstandingLabel(String score) =>
      _isKorean ? '이해도: $score' : 'Understanding: $score';

  String get visualExplanationTitle =>
      _isKorean ? '자세한 설명 & 시각 자료' : 'Detailed explanation';
  String get visualExplanationLoading =>
      _isKorean ? '자세한 내용을 불러오는 중이에요...' : 'Loading detailed explanation...';
  String get visualExplanationError => _isKorean
      ? '시각 자료를 만들지 못했어요. 잠시 후 다시 시도해 주세요.'
      : 'We could not create the visual explanation. Please try again later.';
  String get visualExplanationRetry => _isKorean ? '다시 시도' : 'Try again';
  String visualExplanationFocus(String focus) =>
      _isKorean ? '중점: $focus' : 'Focus: $focus';
  String get visualExplanationImageCaption =>
      _isKorean ? 'AI가 제안하는 시각 자료 예시' : 'Suggested visual aid from AI';
  String get visualExplanationGenerateImage =>
      _isKorean ? '시각 자료 만들기' : 'Generate visual aid';
  String get reviewMissingContent => _isKorean
      ? '이 학습의 설명이 아직 저장되지 않았어요.'
      : 'This lesson explanation is not available yet.';
  String reviewInitialScore(String score) =>
      _isKorean ? '처음 점수: $score' : 'Initial score: $score';
  // (Retention score removed)
  String get reviewRegenerating =>
      _isKorean ? '설명을 다시 불러오는 중이에요...' : 'Generating a new explanation...';
  String get reviewRegenerateButton =>
      _isKorean ? '설명 다시 만들기' : 'Regenerate explanation';
  String get reviewRegenerateError => _isKorean
      ? '설명을 다시 만들지 못했어요. 잠시 후 다시 시도해 주세요.'
      : 'We could not regenerate the explanation. Please try again later.';
  // Retention
    String get retentionAppBarTitle => _isKorean ? '복습 관리' : 'Retention review';
  String get retentionEmptyMessage => _isKorean
      ? '오늘 복습할 내용이 없어요. 계속 학습해 보세요!'
      : 'No reviews due today. Keep learning!';
  String retentionLearnedDate(String date) =>
      _isKorean ? '학습일: $date' : 'Learned: $date';
  String get retentionOpenLesson => _isKorean ? '내용 다시 보기' : 'View lesson';
  String retentionConcept(String concept) =>
      _isKorean ? '개념: $concept' : 'Concept: $concept';
  // Home retention pending label
  String get homeRetentionPending => _isKorean ? '복습 미진행' : 'Reviews pending';

  // Profile
  String get profileAppBarTitle =>
      _isKorean ? '프로필 및 설정' : 'Profile & settings';
  String get profileAnonymousAccount =>
      _isKorean ? '익명 계정' : 'Anonymous account';
  String get profileSubscriptionSection => _isKorean ? '구독' : 'Subscription';
  String profileCurrentPlan(String tier) =>
      _isKorean ? '현재 이용권: $tier' : 'Current plan: $tier';
  String get profileRestorePurchases =>
      _isKorean ? '구매내역 복원' : 'Restore purchases';
  String get profileRestoreResult => _isKorean
      ? '구매 내역을 복원했어요(가능한 경우).'
      : 'Purchases restored (if available).';
  String get profileParentReportTitle =>
      _isKorean ? '학부모 리포트(프리미엄)' : 'Parent report (Premium)';
  String get profileParentReportBody => _isKorean
      ? '프리미엄에서는 학습 시간, 강점, 추천 활동을 요약한 주간 리포트를 제공해요.'
      : 'Premium will unlock a weekly report summarising learning time, strengths,'
            ' and suggested follow-up activities.';
  String get profileSignOut => _isKorean ? '로그아웃' : 'Sign out';
  String get profileSignedOut => _isKorean ? '로그아웃했어요.' : 'Signed out.';

  // Errors and feedback
  String get lessonGenerationError => _isKorean
      ? '학습 내용을 생성하는 중 문제가 발생했어요. 다시 시도해 주세요.'
      : 'Something went wrong while generating the content. Please try again.';
  String get lessonEvaluationError => _isKorean
      ? '설명을 평가할 수 없었어요. 잠시 후 다시 시도해 주세요.'
      : 'We could not evaluate the explanation. Please try again in a moment.';
  String get lessonSaveHistoryError => _isKorean
      ? '학습 기록을 저장하지 못했어요.'
      : 'We were unable to save your learning history.';
  String get feedbackExcellent => _isKorean
      ? '정말 잘했어요! 개념을 확실히 이해했네요.'
      : 'Excellent work! You clearly understand the concept.';
  String get feedbackNice => _isKorean
      ? '잘하고 있어요! 조금만 더 연습하면 완전히 익힐 수 있어요.'
      : 'Nice job! A bit more practice will make it stick.';
  String get feedbackRetry => _isKorean
      ? '설명을 다시 살펴보고 함께 예제를 풀어봐요.'
      : 'Let us revisit the explanation and walk through the example together.';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      const ['ko', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocalizationX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

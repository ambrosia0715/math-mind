import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/ai_content_service.dart';
import '../../../core/services/speech_service.dart';
import '../../../core/services/math_expression_service.dart';
import '../../auth/application/auth_provider.dart';
import '../../subscription/application/subscription_provider.dart';
import '../application/lesson_session_provider.dart';
import '../../../l10n/app_localizations.dart';

/// Clean LaTeX and markdown syntax from text for better display readability
String _cleanTextForDisplay(String text) {
  var cleaned = text;

  // Remove inline LaTeX delimiters: \( ... \) but keep the content
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\\((.*?)\\\)'),
    (match) => match.group(1) ?? '',
  );

  // Remove display LaTeX delimiters: \[ ... \] but keep the content
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\\[(.*?)\\\]'),
    (match) => match.group(1) ?? '',
  );

  // Remove dollar sign math delimiters: $ ... $ but keep the content
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\$(.*?)\$'),
    (match) => match.group(1) ?? '',
  );

  // Remove double dollar sign: $$ ... $$ but keep the content
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\$\$(.*?)\$\$'),
    (match) => match.group(1) ?? '',
  );

  // Remove LaTeX commands and replace with readable alternatives
  cleaned = cleaned.replaceAll(r'\times', '×');
  cleaned = cleaned.replaceAll(r'\div', '÷');
  cleaned = cleaned.replaceAll(r'\pm', '±');
  cleaned = cleaned.replaceAll(r'\le', '≤');
  cleaned = cleaned.replaceAll(r'\ge', '≥');
  cleaned = cleaned.replaceAll(r'\ne', '≠');
  cleaned = cleaned.replaceAll(r'\approx', '≈');
  cleaned = cleaned.replaceAll(r'\pi', 'π');
  cleaned = cleaned.replaceAll(r'\alpha', 'α');
  cleaned = cleaned.replaceAll(r'\beta', 'β');
  cleaned = cleaned.replaceAll(r'\theta', 'θ');
  cleaned = cleaned.replaceAll(r'\sqrt', '√');
  cleaned = cleaned.replaceAll(r'\sum', 'Σ');
  cleaned = cleaned.replaceAll(r'\Sigma', 'Σ');
  cleaned = cleaned.replaceAll(r'\sigma', 'σ');
  cleaned = cleaned.replaceAll(r'\infty', '∞');
  cleaned = cleaned.replaceAll(r'\rightarrow', '→');
  cleaned = cleaned.replaceAll(r'\to', '→');
  cleaned = cleaned.replaceAll(r'\leftarrow', '←');
  cleaned = cleaned.replaceAll(r'\Rightarrow', '⇒');
  cleaned = cleaned.replaceAll(r'\Leftarrow', '⇐');
  cleaned = cleaned.replaceAll(r'\lim', 'lim');
  cleaned = cleaned.replaceAll(r'\int', '∫');
  cleaned = cleaned.replaceAll(r'\cdot', '·');
  cleaned = cleaned.replaceAll(r'\ldots', '…');
  cleaned = cleaned.replaceAll(r'\dots', '…');

  // Convert common fractions to Unicode fraction characters
  cleaned = cleaned.replaceAll('1/2', '½');
  cleaned = cleaned.replaceAll('1/3', '⅓');
  cleaned = cleaned.replaceAll('2/3', '⅔');
  cleaned = cleaned.replaceAll('1/4', '¼');
  cleaned = cleaned.replaceAll('3/4', '¾');
  cleaned = cleaned.replaceAll('1/5', '⅕');
  cleaned = cleaned.replaceAll('2/5', '⅖');
  cleaned = cleaned.replaceAll('3/5', '⅗');
  cleaned = cleaned.replaceAll('4/5', '⅘');
  cleaned = cleaned.replaceAll('1/6', '⅙');
  cleaned = cleaned.replaceAll('5/6', '⅚');
  cleaned = cleaned.replaceAll('1/8', '⅛');
  cleaned = cleaned.replaceAll('3/8', '⅜');
  cleaned = cleaned.replaceAll('5/8', '⅝');
  cleaned = cleaned.replaceAll('7/8', '⅞');

  // Handle LaTeX fraction notation: \frac{numerator}{denominator}
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\frac\s*\{([^}]*)\}\s*\{([^}]*)\}'),
    (match) {
      final numerator = match.group(1)?.trim() ?? '';
      final denominator = match.group(2)?.trim() ?? '';

      // Try to convert to Unicode fraction if it's a common one
      final fraction = '$numerator/$denominator';
      const unicodeFractions = {
        '1/2': '½',
        '1/3': '⅓',
        '2/3': '⅔',
        '1/4': '¼',
        '3/4': '¾',
        '1/5': '⅕',
        '2/5': '⅖',
        '3/5': '⅗',
        '4/5': '⅘',
        '1/6': '⅙',
        '5/6': '⅚',
        '1/8': '⅛',
        '3/8': '⅜',
        '5/8': '⅝',
        '7/8': '⅞',
      };

      if (unicodeFractions.containsKey(fraction)) {
        return unicodeFractions[fraction]!;
      }

      // For other fractions, use clear notation with parentheses if needed
      return '($numerator)/($denominator)';
    },
  );

  // Replace caret (^) with asterisk (*) for multiplication
  // Only replace ^ when it appears to be used as multiplication (e.g., x^2 should stay as is for exponents)
  // For now, keep ^ as is since it's commonly used for exponents in math

  // Replace double asterisks (markdown bold) with nothing, but preserve single asterisks for multiplication
  cleaned = cleaned.replaceAll('**', '');

  // Handle square root notation: \sqrt{x} -> √(x) or √x for simple cases
  cleaned = cleaned.replaceAllMapped(RegExp(r'\\sqrt\s*\{([^}]*)\}'), (match) {
    final content = match.group(1)?.trim() ?? '';
    // If content has operators, add parentheses for clarity
    if (content.contains(RegExp(r'[+\-*/]'))) {
      return '√($content)';
    }
    return '√$content';
  });

  // Handle nth root: \sqrt[n]{x} -> ⁿ√(x)
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'\\sqrt\s*\[([^\]]*)\]\s*\{([^}]*)\}'),
    (match) {
      final root = match.group(1)?.trim() ?? '';
      final content = match.group(2)?.trim() ?? '';

      // Convert root to superscript
      String toSuperscript(String s) {
        const map = {
          '0': '⁰',
          '1': '¹',
          '2': '²',
          '3': '³',
          '4': '⁴',
          '5': '⁵',
          '6': '⁶',
          '7': '⁷',
          '8': '⁸',
          '9': '⁹',
        };
        return s.split('').map((c) => map[c] ?? c).join('');
      }

      final rootSuper = toSuperscript(root);
      if (content.contains(RegExp(r'[+\-*/]'))) {
        return '$rootSuper√($content)';
      }
      return '$rootSuper√$content';
    },
  );

  // Remove remaining LaTeX commands (backslash followed by letters)
  cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');

  // Remove extra backslashes
  cleaned = cleaned.replaceAll(r'\', '');

  // Remove curly braces used in LaTeX but keep content
  cleaned = cleaned.replaceAll('{', '');
  cleaned = cleaned.replaceAll('}', '');

  // Render common math notations more readably
  // 1) Convert simple caret exponents to Unicode superscripts: x^2 -> x², (a+b)^3 -> (a+b)³, b^-1 -> b⁻¹
  String _toSuperscript(String exp) {
    const map = {
      '0': '⁰',
      '1': '¹',
      '2': '²',
      '3': '³',
      '4': '⁴',
      '5': '⁵',
      '6': '⁶',
      '7': '⁷',
      '8': '⁸',
      '9': '⁹',
      '+': '⁺',
      '-': '⁻',
      '(': '⁽',
      ')': '⁾',
    };
    return exp.split('').map((c) => map[c] ?? c).join('');
  }

  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-z0-9\)])\^(-?\d{1,3})'),
    (m) => '${m.group(1)}${_toSuperscript(m.group(2)!)}',
  );

  // 2) Subscripts for simple indices: a_1 -> a₁, a_k -> aₖ, a_n -> aₙ
  String _toSubscript(String text) {
    const map = {
      '0': '₀',
      '1': '₁',
      '2': '₂',
      '3': '₃',
      '4': '₄',
      '5': '₅',
      '6': '₆',
      '7': '₇',
      '8': '₈',
      '9': '₉',
      '+': '₊',
      '-': '₋',
      '(': '₍',
      ')': '₎',
      'a': 'ₐ',
      'e': 'ₑ',
      'h': 'ₕ',
      'i': 'ᵢ',
      'j': 'ⱼ',
      'k': 'ₖ',
      'l': 'ₗ',
      'm': 'ₘ',
      'n': 'ₙ',
      'o': 'ₒ',
      'p': 'ₚ',
      'r': 'ᵣ',
      's': 'ₛ',
      't': 'ₜ',
      'u': 'ᵤ',
      'v': 'ᵥ',
      'x': 'ₓ',
    };
    return text.split('').map((c) => map[c] ?? c).join('');
  }

  // 숫자와 소문자 알파벳 아래첨자 변환: a_1, a_k, a_n 등
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'([A-Za-zπθαβ])_([a-z0-9]{1,3})'),
    (m) => '${m.group(1)}${_toSubscript(m.group(2)!)}',
  );

  // Improve multiplication display: 2*3 -> 2×3, but keep * in expressions like a*b
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(\d)\s*\*\s*(\d)'),
    (m) => '${m.group(1)}×${m.group(2)}',
  );

  // Improve division display: 410 = 25 (간단히 줄였어요) -> clearer format
  // Make sure fractions in text like "410 = 25" are preserved

  // Add spacing around operators for better readability
  cleaned = cleaned.replaceAllMapped(
    RegExp(r'(\d)([\+\-×÷])(\d)'),
    (m) => '${m.group(1)} ${m.group(2)} ${m.group(3)}',
  );

  // Clean up multiple consecutive spaces on the same line (but preserve line breaks)
  cleaned = cleaned.replaceAll(RegExp(r'[ \t]+'), ' ');

  // Normalize line breaks: replace multiple consecutive line breaks with double line break
  cleaned = cleaned.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');

  // Trim each line to remove trailing spaces
  cleaned = cleaned.split('\n').map((line) => line.trim()).join('\n');

  // Trim overall
  cleaned = cleaned.trim();

  return cleaned;
}

// Known math concept keywords to detect in text/topics
const List<String> _knownConceptKeywords = [
  // Sequences & series
  '등비수열', '등차수열', '수열', '수열의 합', '급수',
  // Algebra
  '방정식', '연립방정식', '이차방정식', '부등식', '식', '항등식', '다항식', '인수분해', '완전제곱식',
  // Functions & graphs
  '함수', '삼각함수', '지수함수', '로그함수', '그래프', '좌표', '기울기', '절편', '꼭짓점',
  // Arithmetic & numbers
  '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율',
  // Geometry
  '도형', '기하', '삼각형', '사각형', '원', '원의 넓이', '둘레', '피타고라스', '벡터', '행렬',
  // Calculus
  '미분', '적분', '극한',
  // Probability & statistics
  '확률', '통계', '평균', '중앙값', '최빈값', '표준편차',
  // Trig details
  '사인', '코사인', '탄젠트',
  // Others
  '로그', '지수', '집합',
];

bool _containsNumberOrOperator(String s) =>
    RegExp(r'[0-9+\-*/×÷=^]').hasMatch(s);

// Topic like just a keyword? If so, we can opt to hide suggestions block
bool _isGenericConceptQuery(String? topic) {
  final t = (topic ?? '').trim();
  if (t.isEmpty) return false;
  if (_containsNumberOrOperator(t)) return false; // it's a problem-like query
  // Exact or close match to known keywords
  if (_knownConceptKeywords.contains(t)) return true;
  // Also treat short keyword-like topics as generic
  if (t.length <= 6 &&
      _knownConceptKeywords.any((k) => t == k || k.contains(t))) {
    return true;
  }
  return false;
}

List<String> _extractConceptKeywordsFromText(String text) {
  final lower = text.toLowerCase();
  final results = <String>{};
  for (final kw in _knownConceptKeywords) {
    if (kw.isEmpty) continue;
    // Check both original and lower-cased (mainly for English words)
    if (text.contains(kw)) {
      results.add(kw);
      continue;
    }
    final kwLower = kw.toLowerCase();
    if (lower.contains(kwLower)) {
      results.add(kw);
    }
  }
  return results.toList(growable: false);
}

List<String> _findRelatedConceptKeywords(LessonSessionProvider session) {
  // Prefer AI-provided breakdowns when available
  final fromBreakdown = session.conceptBreakdown
      .map((c) => c.name.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  final set = <String>{...fromBreakdown};
  if (set.isEmpty) {
    final topic = session.topic ?? '';
    final explanation = session.conceptExplanation ?? '';
    final combined = '$topic\n$explanation';
    set.addAll(_extractConceptKeywordsFromText(combined));
  }
  // Remove current topic if it matches exactly
  final t = (session.topic ?? '').trim();
  set.removeWhere((e) => e == t);
  return set.take(8).toList(growable: false);
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  static const routeName = '/lesson';

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _topicController = TextEditingController();
  final _explanationController = TextEditingController();
  int _selectedDifficulty = 10;
  bool _isListening = false;
  bool _isVisualLoading = false;
  // Detailed explanation cache key (topic + difficulty)
  String? _detailedCacheKey;
  String? _visualCacheKey;
  String? _visualDescription;
  String? _visualFocusHint;
  Future<VisualExplanationImage?>? _visualImageTask;
  VisualExplanationImage? _visualImage;

  // Image picker and text recognition
  final _imagePicker = ImagePicker();
  bool _isRecognizingText = false;

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
    setState(_resetVisualState);
  }

  void _resetVisualState() {
    _detailedCacheKey = null;
    _visualCacheKey = null;
    _visualDescription = null;
    _visualFocusHint = null;
    _isVisualLoading = false;
    _visualImageTask = null;
    _visualImage = null;
  }

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 세션 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<LessonSessionProvider>();
      session.reset();
      _topicController.clear();
      _explanationController.clear();
      setState(() {
        _selectedDifficulty = 10;
        _resetVisualState();
      });

      // Arguments에서 초기 주제를 받았으면 설정하고 바로 수업 시작
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final initialTopic = args['initialTopic'] as String?;
        if (initialTopic != null && initialTopic.trim().isNotEmpty) {
          _topicController.text = initialTopic;
          // 자동으로 수업 시작
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startLessonWithTopic(context, session, initialTopic);
            }
          });
        }
      }
    });
  }

  _VisualAidPlan _buildVisualAidPlan(LessonSessionProvider session) {
    final topic = (session.topic ?? '').trim();
    final explanation = (session.conceptExplanation ?? '').trim();
    final raw = '$topic\n$explanation';
    final lower = raw.toLowerCase();

    final baseConcept =
        (session.selectedConcept?.name ?? session.detectedConcept ?? topic)
            .trim();
    final fallbackFocus = baseConcept.isNotEmpty
        ? '$baseConcept을 떠올릴 수 있는 간단한 그림을 제안해 주세요.'
        : '핵심 개념을 떠올릴 수 있는 간단한 그림을 제안해 주세요.';

    if (_containsAny(lower, const [
      'graph',
      'coordinate',
      'function',
      'equation',
      'linear',
      'quadratic',
      'plot',
      'slope',
      '\uadf8\ub798\ud504',
      '\uc88c\ud45c',
      '\ud568\uc218',
      '\ubc29\uc815\uc2dd',
    ])) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '좌표축에 눈금을 표시한 좌표평면을 그리고 함수를 스케치하세요. 주요 절편과 꼭짓점을 표시하세요.',
      );
    }

    if (_containsAny(lower, const [
      'triangle',
      'trig',
      'sin',
      'cos',
      'tan',
      '\uc0bc\uac01',
      '\uc0ac\uc778',
      '\ucf54\uc0ac\uc778',
      '\ud0c4\uc824\ud2f0',
      '\uac01\ub3c4',
    ])) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '직각삼각형을 그리고 변과 각을 라벨링한 뒤, 각 변의 비가 사인·코사인·탄젠트에 어떻게 대응되는지 보여 주세요.',
      );
    }

    if (_containsAny(lower, const [
          'fraction',
          'numerator',
          'denominator',
          'divide',
          '\ubd84\uc218',
          '\ubd84\uc790',
          '\ubd84\ubaa8',
          '\ub098\ub205',
          '\ub098\ub204',
        ]) ||
        raw.contains('/')) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '원을 또는 직사각형을 같은 크기의 조각으로 나누고, 분수를 나타내는 부분을 색칠해 보여 주세요.',
      );
    }

    if (_containsAny(lower, const [
          'addition',
          'sum',
          '\ub35c\uc148',
          '\ub354\ud558\uae30',
        ]) ||
        raw.contains('+')) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '사과나 블록 그림으로 1개 + 2개 = 3개가 되는 과정을 단계별로 보여 주세요.',
      );
    }

    if (_containsAny(lower, const [
          'difference',
          'subtract',
          '\ube7c\uc148',
          '\ube7c\uae30',
        ]) ||
        raw.contains('-')) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '모둠에서 물건을 빼는 장면을 그려 남은 양이 분명하게 보이도록 해 주세요.',
      );
    }

    if (_containsAny(lower, const [
      'multiplication',
      'times',
      'array',
      '\uacf1\uc148',
      '\uacf1\ud558\uae30',
      '\ubc30\uc218',
    ])) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '배열(격자)을 사용해 곱셈을 설명하고, 행과 열에 라벨을 달아 주세요.',
      );
    }

    if (_containsAny(lower, const [
      'area',
      'shape',
      'circle',
      'rectangle',
      'square',
      'perimeter',
      '\uba74\uc801',
      '\ub113\uc774',
      '\ub3c4\ud615',
      '\uc0ac\uac01\ud615',
      '\uc6d0',
      '\ubc18\uc9c0\ub984',
      '\ub458\ub808',
    ])) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '관련 도형을 그리고 길이·각도·넓이 등을 표시하여 개념을 설명해 주세요.',
      );
    }

    if (_containsAny(lower, const [
          'ratio',
          'percent',
          'probability',
          'statistics',
          '\ube44\uc728',
          '\ubc31\ubd84\uc728',
          '\ud655\ub960',
          '\ud1b5\uacc4',
          '\ub370\uc774\ud130',
        ]) ||
        raw.contains('%')) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '막대그래프 또는 파이차트로 비율을 명확하게 비교해 주세요.',
      );
    }

    if (_containsAny(lower, const [
      'number line',
      'timeline',
      '\uc218\uc9dd\uc120',
      '\uc2dc\uac04',
    ])) {
      return const _VisualAidPlan(
        needsImage: true,
        focus: '눈금이 있는 수직선을 그리고 설명에 사용된 주요 지점을 강조해 주세요.',
      );
    }

    return _VisualAidPlan(needsImage: false, focus: fallbackFocus);
  }

  bool _containsAny(String text, Iterable<String> keywords) {
    for (final keyword in keywords) {
      if (keyword.isEmpty) continue;
      if (text.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  // 더 자세히 보기: 예시와 풀이를 포함한 자세한 설명 생성 (주제+난이도로 캐시)
  Future<void> _handleDetailedExplanation(
    BuildContext context,
    LessonSessionProvider session,
  ) async {
    if (_isVisualLoading) {
      return;
    }

    final topic = session.topic;
    final explanation = session.conceptExplanation;
    if (topic == null || explanation == null) {
      return;
    }

    // 캐시 키: 주제 + 난이도
    final cacheKey = '$topic|${_selectedDifficulty}';

    // 이미 자세한 설명이 있고 같은 주제+난이도면 재조회하지 않음
    if (_detailedCacheKey == cacheKey && session.detailedExplanation != null) {
      if (!context.mounted) return;
      await _presentDetailedExplanationSheet(context, session);
      return;
    }

    final aiService = context.read<AiContentService>();
    final learnerName =
        context.read<AuthProvider>().currentUser?.displayName ??
        context.l10n.generalLearnerFallback;
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    setState(() {
      _isVisualLoading = true;
    });

    try {
      // AI에게 자세한 설명(예시, 풀이 포함) 요청
      final detailedText = await aiService.createDetailedExplanation(
        topic: topic,
        difficulty: _selectedDifficulty,
        learnerName: learnerName,
        baseExplanation: explanation,
      );

      if (!mounted) return;

      setState(() {
        _detailedCacheKey = cacheKey;
      });

      session.setDetailedExplanation(detailedText);

      if (!context.mounted) return;
      await _presentDetailedExplanationSheet(context, session);
    } catch (error, stackTrace) {
      debugPrint('Detailed explanation failed: $error\n$stackTrace');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.visualExplanationError), // 적절한 에러 메시지로 변경 가능
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVisualLoading = false);
      }
    }
  }

  // 자세한 설명 시트 표시
  Future<void> _presentDetailedExplanationSheet(
    BuildContext context,
    LessonSessionProvider session,
  ) async {
    final detailedText = session.detailedExplanation;
    final topic = session.topic;
    if (detailedText == null || topic == null || !context.mounted) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 40,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '더 자세히 보기',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: l10n.generalClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      _cleanTextForDisplay(detailedText),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.generalClose),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleVisualExplanation(
    BuildContext context,
    LessonSessionProvider session,
  ) async {
    if (_isVisualLoading) {
      return;
    }

    final topic = session.topic;
    final explanation = session.conceptExplanation;
    if (topic == null || explanation == null) {
      return;
    }

    final plan = _buildVisualAidPlan(session);
    final focus = plan.focus;
    final cacheKey = '$topic|$focus|${session.targetAge}';

    if (_visualCacheKey == cacheKey && _visualDescription != null) {
      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
      return;
    }

    final aiService = context.read<AiContentService>();
    final learnerName =
        context.read<AuthProvider>().currentUser?.displayName ??
        context.l10n.generalLearnerFallback;
    final messenger = ScaffoldMessenger.of(context);
    final visualErrorMessage = context.l10n.visualExplanationError;

    setState(() {
      _isVisualLoading = true;
    });

    try {
      final result = await aiService.createVisualExplanation(
        topic: topic,
        difficulty: session.targetAge,
        learnerName: learnerName,
        requestImage: plan.needsImage,
        imageFocus: focus,
        baseExplanation: explanation,
      );

      if (!mounted) return;

      setState(() {
        _visualCacheKey = cacheKey;
        _visualDescription = result.description;
        _visualFocusHint = focus;
        _visualImageTask = result.imageTask;
        // If an immediate image is available (future-less), cache it
        if (result.imageBytes != null || result.imageUrl != null) {
          _visualImage = VisualExplanationImage(
            imageBytes: result.imageBytes,
            imageUrl: result.imageUrl,
          );
        } else {
          _visualImage = null;
        }
      });

      if (!context.mounted) return;
      await _presentVisualExplanationSheet(context, session, focus);
    } catch (error, stackTrace) {
      debugPrint('Visual explanation failed: $error\n$stackTrace');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(visualErrorMessage)));
    } finally {
      if (mounted) {
        setState(() => _isVisualLoading = false);
      }
    }
  }

  Future<void> _presentVisualExplanationSheet(
    BuildContext context,
    LessonSessionProvider session,
    String focus,
  ) async {
    final description = _visualDescription;
    final topic = session.topic;
    if (description == null || topic == null || !context.mounted) {
      return;
    }

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final resolvedFocus = focus.trim().isNotEmpty
        ? focus.trim()
        : (_visualFocusHint?.trim() ??
              session.selectedConcept?.name ??
              session.topic ??
              '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 40,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.visualExplanationTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close),
                        tooltip: l10n.generalClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (resolvedFocus.isNotEmpty) ...[
                    Text(
                      _cleanTextForDisplay(
                        l10n.visualExplanationFocus(resolvedFocus),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  // Related concept keywords chips (tap to start a new lesson)
                  if (!_isGenericConceptQuery(topic))
                    Builder(
                      builder: (context) {
                        final keywords = _findRelatedConceptKeywords(session);
                        if (keywords.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '이 문제를 풀기 전에 알아두면 좋은 개념',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final kw in keywords)
                                  ActionChip(
                                    label: Text('# $kw'),
                                    onPressed: () async {
                                      if (sheetContext.mounted) {
                                        Navigator.of(sheetContext).pop();
                                      }
                                      // New policy: set topic and show a short guide instead of starting immediately
                                      if (context.mounted) {
                                        final ai = context
                                            .read<AiContentService>();
                                        final guide = await ai
                                            .buildShortConceptGuide(kw);
                                        final state = context
                                            .findAncestorStateOfType<
                                              _LessonScreenState
                                            >();
                                        if (state != null) {
                                          state._topicController.text = kw;
                                        }
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(guide)),
                                        );
                                      }
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withOpacity(
                          0.5,
                        ),
                      ),
                    ),
                    child: Text(
                      _cleanTextForDisplay(description),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Optional illustrative image (if available/requested)
                  if (_visualImage != null || _visualImageTask != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildVisualImageWidget(theme),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close),
                      label: Text(l10n.generalClose),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Heuristic: does user's topic look like a math concept or problem?
  bool _looksLikeMathTopic(String text) {
    final t = text.trim().toLowerCase();
    if (t.isEmpty) return false;

    // Contains numbers and math operators or equality signs
    final hasNumber = RegExp(r'[0-9]').hasMatch(t);
    final hasOp = RegExp(r'[+\-*/×÷^=(){}\[\]]').hasMatch(t);
    if (hasNumber && hasOp) return true;

    // Common math keywords (Korean + English)
    const keywords = [
      // Korean
      '분수', '소수', '정수', '자연수', '유리수', '무리수', '비율', '비례', '백분율', '확률', '통계',
      '평균', '중앙값', '최빈값', '편차', '표준편차',
      '방정식', '연립방정식', '이차방정식', '부등식', '식', '항', '항등식',
      '함수', '그래프', '좌표', '기울기', '절편', '꼭짓점', '최대값', '최소값',
      '도형', '기하', '삼각형', '사각형', '원', '원의', '각도', '사인', '코사인', '탄젠트',
      '넓이', '둘레', '부피', '표면적', '피타고라스',
      '수열', '등차', '등비', '수열의 합',
      '행렬', '벡터', '집합', '확장', '미분', '적분', '극한', '로그', '지수', '다항식',
      // 연산 관련 단어
      '더하기', '덧셈', '빼기', '뺄셈', '곱하기', '곱셈', '나누기', '나눗셈',
      // English
      'fraction',
      'decimal',
      'integer',
      'rational',
      'irrational',
      'ratio',
      'proportion',
      'percent',
      'percentage',
      'probability',
      'statistics',
      'mean',
      'median',
      'mode',
      'equation', 'inequality', 'quadratic', 'polynomial',
      'function',
      'graph',
      'coordinate',
      'slope',
      'intercept',
      'vertex',
      'maximum',
      'minimum',
      'geometry',
      'triangle',
      'rectangle',
      'square',
      'circle',
      'angle',
      'sine',
      'cosine',
      'tangent',
      'area', 'perimeter', 'volume', 'surface area', 'pythagorean',
      'sequence', 'series', 'arithmetic', 'geometric',
      'matrix',
      'vector',
      'set',
      'derivative',
      'integral',
      'limit',
      'log',
      'exponential',
    ];

    for (final k in keywords) {
      if (t.contains(k)) return true;
    }

    return false;
  }

  Widget _buildVisualImageWidget(ThemeData theme) {
    // If we already have an image, render it immediately
    if (_visualImage != null && _visualImage!.hasData) {
      final img = _visualImage!;
      if (img.imageBytes != null) {
        return Image.memory(img.imageBytes!, fit: BoxFit.cover);
      }
      if (img.imageUrl != null) {
        return Image.network(
          img.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final value = progress.expectedTotalBytes != null
                ? progress.cumulativeBytesLoaded /
                      (progress.expectedTotalBytes ?? 1)
                : null;
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(value: value)),
            );
          },
          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
        );
      }
    }

    // Otherwise, if there's a task, build with FutureBuilder
    if (_visualImageTask != null) {
      return FutureBuilder<VisualExplanationImage?>(
        future: _visualImageTask,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final result = snapshot.data;
          if (result == null || !result.hasData) {
            return const SizedBox.shrink();
          }
          _visualImage = result; // cache for next time
          if (result.imageBytes != null) {
            return Image.memory(result.imageBytes!, fit: BoxFit.cover);
          }
          if (result.imageUrl != null) {
            return Image.network(
              result.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink(),
            );
          }
          return const SizedBox.shrink();
        },
      );
    }

    return const SizedBox.shrink();
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
      difficulty: _selectedDifficulty,
      learnerName:
          auth.currentUser?.displayName ?? context.l10n.generalLearnerFallback,
    );
    subscription.registerQuestionAsked();
    session.clearConceptSuggestions();
    _topicController.text = trimmedTopic;
    if (!mounted) return;
    setState(_resetVisualState);
  }

  /// Show dialog to choose camera or gallery
  Future<void> _showImageSourceDialog() async {
    final l10n = context.l10n;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사진에서 문제 가져오기'),
        content: const Text('카메라로 촬영하거나 갤러리에서 선택해 주세요.'),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageAndRecognizeText(ImageSource.camera);
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('카메라'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _pickImageAndRecognizeText(ImageSource.gallery);
            },
            icon: const Icon(Icons.photo_library),
            label: const Text('갤러리'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
        ],
      ),
    );
  }

  /// Pick image from camera or gallery and recognize text
  Future<void> _pickImageAndRecognizeText(ImageSource source) async {
    final l10n = context.l10n;

    try {
      setState(() => _isRecognizingText = true);

      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80, // Reduce quality for faster processing
      );

      if (pickedFile == null) {
        setState(() => _isRecognizingText = false);
        return;
      }

      // Recognize text from the picked image
      final mathService = MathExpressionService();
      final recognizedText = await mathService.recognizeFromPath(
        pickedFile.path,
      );

      if (!mounted) return;

      if (recognizedText != null && recognizedText.trim().isNotEmpty) {
        // Set the recognized text to the topic field
        _topicController.text = recognizedText.trim();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('텍스트를 인식했어요: ${recognizedText.trim()}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미지에서 텍스트를 찾을 수 없어요. 다른 이미지를 시도해 보세요.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Clean up the math service
      await mathService.dispose();
    } catch (e) {
      debugPrint('Image text recognition error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미지 처리 중 문제가 발생했어요. 다시 시도해 주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRecognizingText = false);
      }
    }
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
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E85).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: Color(0xFF2C3E85),
              ),
            ),
            const SizedBox(width: 10),
            Text(l10n.lessonAppBarTitle),
          ],
        ),
        actions: [
          // 진행 상태 표시
          if (session.stage == LessonStage.generatingContent ||
              session.stage == LessonStage.evaluating)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: const Color(0xFF2C3E85),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          _buildTopicCard(context, session),
          const SizedBox(height: 20),
          if (session.conceptExplanation != null)
            _ExplanationCard(
              content: session.conceptExplanation!,
              onVisualPressed: () =>
                  _handleDetailedExplanation(context, session),
              isVisualLoading: _isVisualLoading,
            ),
          const SizedBox(height: 20),
          if (session.conceptExplanation != null)
            _buildEvaluationCard(context, session),
          const SizedBox(height: 20),
          if (session.aiFeedback != null)
            _FeedbackCard(
              score: session.initialScore,
              feedback: session.aiFeedback!,
            ),
          if (session.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      session.errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),
          // 저장 버튼
          if (session.conceptExplanation != null)
            Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E85), Color(0xFF5B7FD4)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2C3E85).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () async {
                    await session.commitLesson();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.lessonSaveAndReturn,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
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
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _topicController,
                    decoration: InputDecoration(
                      labelText: l10n.lessonTopicLabel,
                      hintText: l10n.lessonTopicHint,
                    ),
                    onChanged: (value) => _handlePromptChanged(value, session),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isRecognizingText ? null : _showImageSourceDialog,
                  icon: _isRecognizingText
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  tooltip: '사진에서 문제 가져오기',
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    foregroundColor: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
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
                Text('난이도:'),
                Expanded(
                  child: Slider(
                    value: _selectedDifficulty.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: '단계 $_selectedDifficulty',
                    onChanged:
                        stage == LessonStage.generatingContent ||
                            stage == LessonStage.evaluating
                        ? null
                        : (value) {
                            final newLevel = value.round();
                            if (newLevel != _selectedDifficulty) {
                              _resetGeneratedContent(session);
                              setState(() => _selectedDifficulty = newLevel);
                            }
                          },
                  ),
                ),
                Text('단계 $_selectedDifficulty'),
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
                      : () async {
                          final raw = _topicController.text;
                          if (!_looksLikeMathTopic(raw)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  context.l10n.lessonTopicNeedsMath,
                                ),
                              ),
                            );
                            return;
                          }
                          await _startLessonWithTopic(context, session, raw);
                        },
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(l10n.lessonGenerate),
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
            onSelected: (selected) async {
              if (selected) {
                session.selectConcept(concept);
                // New policy: set the topic field and show a short concept guide instead of starting immediately
                final ai = context.read<AiContentService>();
                final guide = await ai.buildShortConceptGuide(concept.name);
                _topicController.text = concept.name;
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(guide)));
                }
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
            const SizedBox(height: 8),
            // 개념 중심 안내 문구
            Text(
              _buildConceptualPrompt(session),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationController,
              decoration: InputDecoration(
                labelText: l10n.lessonYourExplanation,
                hintText:
                    '예: 함수는 입력값마다 하나의 출력값이 정해지는 대응 관계예요. 미분은 순간 변화율을 구하는 방법이에요.',
              ),
              minLines: 4,
              maxLines: 8,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
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

  String _buildConceptualPrompt(LessonSessionProvider session) {
    final topic = (session.topic ?? '').toLowerCase();
    final keywords = session.conceptBreakdown.map((e) => e.name).toList();

    // 주제/키워드 기반 개념 중심 질문 생성
    if (topic.contains('함수') || keywords.any((k) => k.contains('함수'))) {
      return '💡 함수란 무엇이고, 어떤 성질을 가지고 있나요?';
    }
    if (topic.contains('미분') || keywords.any((k) => k.contains('미분'))) {
      return '💡 미분은 무엇을 의미하고, 어디에 사용되나요?';
    }
    if (topic.contains('적분') || keywords.any((k) => k.contains('적분'))) {
      return '💡 적분의 기본 개념과 넓이와의 관계를 설명해 주세요.';
    }
    if (topic.contains('수열') || keywords.any((k) => k.contains('수열'))) {
      return '💡 수열의 정의와 등차/등비수열의 차이를 설명해 주세요.';
    }
    if (topic.contains('확률') || keywords.any((k) => k.contains('확률'))) {
      return '💡 확률이란 무엇이고, 어떻게 계산하나요?';
    }
    if (topic.contains('방정식') || keywords.any((k) => k.contains('방정식'))) {
      return '💡 방정식이란 무엇이고, 어떻게 풀어야 하나요?';
    }
    if (topic.contains('그래프') || keywords.any((k) => k.contains('그래프'))) {
      return '💡 그래프의 의미와 좌표 개념을 설명해 주세요.';
    }

    // 일반 fallback
    return '💡 이 개념의 핵심 정의와 성질, 활용 방법을 설명해 주세요.';
  }
}

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard({
    required this.content,
    required this.onVisualPressed,
    required this.isVisualLoading,
  });

  final String content;
  final VoidCallback? onVisualPressed;
  final bool isVisualLoading;

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
            // Suggest related concept keywords at the top of the explanation
            Builder(
              builder: (ctx) {
                final session = ctx.read<LessonSessionProvider>();
                if (_isGenericConceptQuery(session.topic)) {
                  return const SizedBox.shrink();
                }
                final keywords = _findRelatedConceptKeywords(session);
                if (keywords.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '관련 개념으로 다시 배워 보기',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final kw in keywords)
                          ActionChip(
                            label: Text('# $kw'),
                            onPressed: () async {
                              // New policy: do not start immediately. Set the topic field and show a short guide.
                              final ai = ctx.read<AiContentService>();
                              final guide = await ai.buildShortConceptGuide(kw);
                              final state = ctx
                                  .findAncestorStateOfType<
                                    _LessonScreenState
                                  >();
                              if (state != null) {
                                state._topicController.text = kw;
                              }
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(
                                  ctx,
                                ).showSnackBar(SnackBar(content: Text(guide)));
                              }
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
            Text(_cleanTextForDisplay(content)),
            if (onVisualPressed != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: isVisualLoading ? null : onVisualPressed,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(
                    isVisualLoading
                        ? l10n.visualExplanationLoading
                        : l10n.lessonShowMoreDetail,
                  ),
                ),
              ),
            ],
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
            Text(_cleanTextForDisplay(feedback)),
          ],
        ),
      ),
    );
  }
}

class _VisualAidPlan {
  const _VisualAidPlan({required this.needsImage, required this.focus});

  final bool needsImage;
  final String focus;
}

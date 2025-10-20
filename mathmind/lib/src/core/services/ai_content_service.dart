import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:openai_dart/openai_dart.dart';

import '../config/app_env.dart';

class AiContentService {
  AiContentService(this._env);

  final AppEnv _env;

  OpenAIClient? _client;

  OpenAIClient? get _clientOrNull {
    if (_env.openAIApiKey.isEmpty) {
      return null;
    }
    return _client ??= OpenAIClient(apiKey: _env.openAIApiKey);
  }

  Future<String> explainConcept({
    required String topic,
    required int difficulty,
    required String learnerName,
    bool includeVisualPrompt = false,
  }) async {
    // Removed unused prompt variable

    final client = _clientOrNull;
    if (client == null) {
      return _fallbackExplanation(topic, difficulty);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '당신은 MathMind이며, 학습자의 난이도에 맞춰 설명해 주는 격려하는 수학 튜터입니다. '
                  '어려운 표현이 필요하면 간단한 풀이를 덧붙이고, 가능한 한 학습자가 평소 사용하는 쉬운 단어를 선택하세요. '
                  '모든 응답은 한국어로 작성하세요.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '수학 개념 "$topic"을(를) 난이도 $difficulty 단계에 맞춰 설명해 주세요. 학습자 이름: $learnerName',
              ),
            ),
          ],
        ),
      );
      final message = response.choices.first.message;
      final output = message.maybeMap(
        assistant: (assistant) => assistant.content,
        orElse: () => null,
      );
      if (output == null || output.trim().isEmpty) {
        return _fallbackExplanation(topic, difficulty);
      }
      return output.trim();
    } catch (error, stackTrace) {
      debugPrint('Failed to call OpenAI: $error\n$stackTrace');
      return _fallbackExplanation(topic, difficulty);
    }
  }

  Future<List<ConceptBreakdown>> analyzeProblemConcepts({
    required String problem,
    required int difficulty,
  }) async {
    final client = _clientOrNull;
    if (client == null) {
      return _fallbackConceptBreakdown(problem);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          responseFormat: const ResponseFormat.jsonSchema(
            jsonSchema: JsonSchemaObject(
              name: 'concept_breakdown',
              schema: {
                'type': 'object',
                'properties': {
                  'concepts': {
                    'type': 'array',
                    'items': {
                      'type': 'object',
                      'properties': {
                        'name': {'type': 'string'},
                        'summary': {'type': 'string'},
                      },
                      'required': ['name'],
                    },
                    'minItems': 1,
                    'maxItems': 3,
                  },
                },
                'required': ['concepts'],
              },
            ),
          ),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '주어진 수학 문제를 해결할 때 필요한 핵심 개념 1~3개를 순서대로 고르고, '
                  '각 개념마다 어린 학습자에게 설명하듯 쉬운 말로 한두 문장 설명을 덧붙이세요. '
                  '모든 응답은 JSON으로만 반환하세요.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '문제: $problem\n난이도: $difficulty 단계',
              ),
            ),
          ],
        ),
      );

      final payload = response.choices.first.message.maybeMap(
        assistant: (assistant) => assistant.content,
        orElse: () => null,
      );

      if (payload == null || payload.trim().isEmpty) {
        return _fallbackConceptBreakdown(problem);
      }

      final decoded = jsonDecode(payload) as Map<String, dynamic>?;
      final conceptsJson = decoded?['concepts'];
      if (conceptsJson is! List) {
        return _fallbackConceptBreakdown(problem);
      }

      final concepts = conceptsJson
          .map(
            (json) => json is Map<String, dynamic>
                ? ConceptBreakdown.fromJson(json)
                : null,
          )
          .whereType<ConceptBreakdown>()
          .toList();

      return concepts.isNotEmpty
          ? concepts
          : _fallbackConceptBreakdown(problem);
    } catch (error, stackTrace) {
      debugPrint('Concept breakdown failed: $error\n$stackTrace');
      return _fallbackConceptBreakdown(problem);
    }
  }

  // Return only the total score (for existing call sites)
  Future<int> evaluateUnderstanding({
    required String topic,
    required String expectedConcept,
    required String learnerExplanation,
    int? difficulty,
  }) async {
    final result = await evaluateUnderstandingDetailed(
      topic: topic,
      expectedConcept: expectedConcept,
      learnerExplanation: learnerExplanation,
      difficulty: difficulty,
    );
    return result.score;
  }

  // New detailed conceptual evaluation (score + 3 sub-scores + feedback)
  Future<ConceptualEvaluation> evaluateUnderstandingDetailed({
    required String topic,
    required String expectedConcept,
    required String learnerExplanation,
    int? difficulty,
  }) async {
    final client = _clientOrNull;
    if (client == null) {
      final h = _heuristicConceptualComponents(
        learnerExplanation,
        topic: topic,
        expectedConcept: expectedConcept,
      );
      final weighted = _weightedTotal(h.recall, h.application, h.integration, difficulty: difficulty);
      return ConceptualEvaluation(
        score: weighted,
        recall: h.recall,
        application: h.application,
        integration: h.integration,
        feedback: _fallbackConceptualFeedback(h.recall, h.application, h.integration),
      );
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          responseFormat: const ResponseFormat.jsonSchema(
            jsonSchema: JsonSchemaObject(
              name: 'conceptual_understanding',
              schema: {
                'type': 'object',
                'properties': {
                  'score': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                  'feedback': {'type': 'string'},
                  'recall': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                  'application': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                  'integration': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                },
                'required': ['score', 'feedback', 'recall', 'application', 'integration'],
              },
            ),
          ),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '당신은 학생의 개념적 이해도를 평가합니다. '
                  '다음 세 기준에 따라 점수를 주세요: \n'
                  '① 개념 인식(Recall): 핵심 개념/정의/용어를 올바르게 언급했는가?\n'
                  '② 개념 적용(Application): 문제 해결/절차/공식 사용을 설명했는가?\n'
                  '③ 개념 연결(Integration): 개념 간 관계/이유/조건을 스스로 정리했는가?\n'
                  '각 항목은 0~100점, 총합 score는 이들의 가중 평균(각 1/3) 또는 합리적인 판단으로 산정하세요.\n'
                  'feedback은 한국어로 짧고 친근하게 작성하고, 부족한 부분에 대한 한 줄 개선 포인트를 포함하세요.\n'
                  '반드시 JSON만 반환하세요.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '주제: $topic\n기대하는 개념: $expectedConcept\n학생 설명: $learnerExplanation',
              ),
            ),
          ],
        ),
      );

      final payload = response.choices.first.message.maybeMap(
        assistant: (assistant) => assistant.content ?? '',
        orElse: () => '',
      );

      if (payload.isEmpty) {
        final h = _heuristicConceptualComponents(
          learnerExplanation,
          topic: topic,
          expectedConcept: expectedConcept,
        );
        final weighted = _weightedTotal(h.recall, h.application, h.integration, difficulty: difficulty);
        return ConceptualEvaluation(
          score: weighted,
          recall: h.recall,
          application: h.application,
          integration: h.integration,
          feedback: _fallbackConceptualFeedback(h.recall, h.application, h.integration),
        );
      }

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      final score = (decoded['score'] as num?)?.clamp(0, 100).round();
      final recall = (decoded['recall'] as num?)?.clamp(0, 100).round();
      final application = (decoded['application'] as num?)?.clamp(0, 100).round();
      final integration = (decoded['integration'] as num?)?.clamp(0, 100).round();
      final feedback = (decoded['feedback'] as String?)?.trim();
      if ([score, recall, application, integration].any((e) => e == null)) {
        final h = _heuristicConceptualComponents(
          learnerExplanation,
          topic: topic,
          expectedConcept: expectedConcept,
        );
        final weighted = _weightedTotal(
          recall ?? h.recall,
          application ?? h.application,
          integration ?? h.integration,
          difficulty: difficulty,
        );
        return ConceptualEvaluation(
          score: weighted,
          recall: recall ?? h.recall,
          application: application ?? h.application,
          integration: integration ?? h.integration,
          feedback: feedback?.isNotEmpty == true ? feedback! : _fallbackConceptualFeedback(h.recall, h.application, h.integration),
        );
      }
      final weighted = _weightedTotal(recall!, application!, integration!, difficulty: difficulty);
      return ConceptualEvaluation(
        score: weighted,
        recall: recall,
        application: application,
        integration: integration,
        feedback: (feedback != null && feedback.isNotEmpty)
            ? feedback
    : _fallbackConceptualFeedback(recall, application, integration),
      );
    } catch (error, stackTrace) {
      debugPrint('OpenAI evaluation failed: $error\n$stackTrace');
      final h = _heuristicConceptualComponents(
        learnerExplanation,
        topic: topic,
        expectedConcept: expectedConcept,
      );
      final weighted = _weightedTotal(h.recall, h.application, h.integration, difficulty: difficulty);
      return ConceptualEvaluation(
        score: weighted,
        recall: h.recall,
        application: h.application,
        integration: h.integration,
        feedback: _fallbackConceptualFeedback(h.recall, h.application, h.integration),
      );
    }
  }

  Future<String> detectConceptFromProblem(String problemStatement) async {
    final client = _clientOrNull;
    if (client == null) {
      return _fallbackDetectedConcept(problemStatement);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '사용자의 문제에서 다루는 핵심 수학 개념을 한국어 명사구로 짧게 알려 주세요. '
                  '예: "분수 덧셈", "피타고라스 정리", "이차방정식".',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                problemStatement,
              ),
            ),
          ],
        ),
      );

      final concept = response.choices.first.message.maybeMap(
        assistant: (assistant) => assistant.content ?? '',
        orElse: () => '',
      );

      return concept.trim().isNotEmpty
          ? concept.trim()
          : _fallbackDetectedConcept(problemStatement);
    } catch (error, stackTrace) {
      debugPrint('Concept detection failed: $error\n$stackTrace');
      return _fallbackDetectedConcept(problemStatement);
    }
  }

  Future<VisualExplanationImage?> generateVisualAid({
    required String topic,
    required String focus,
    required int difficulty,
  }) async {
    final client = _clientOrNull;
    if (client == null) {
      return null;
    }

    try {
      final prompt = [
        '다음 주제 "$topic"을(를) 설명하는 데 도움이 되는, 학생 친화적인 삽화를 만들어 주세요.',
        '특히 다음 요소에 집중해 주세요: $focus.',
        if (difficulty < 3)
          '과일, 장난감, 블록 등 친숙한 사물을 사용하고, 색상은 선명하게, 라벨은 최소화해 주세요.'
        else
          '난이도 $difficulty 단계에 적합한 깔끔한 도식, 라벨이 있는 축/도형, 간결한 주석을 사용해 주세요.',
        '레이아웃은 단순하게 유지하고 한눈에 개념이 이해되도록 해 주세요.',
        '최종 출력 설명(텍스트)은 반드시 한국어로 작성하세요.',
      ].join(' ');

      final response = await client.createImage(
        request: CreateImageRequest(
          prompt: prompt,
          model: const CreateImageRequestModel.model(ImageModels.gptImage1),
          size: ImageSize.v1024x1024,
          responseFormat: ImageResponseFormat.b64Json,
        ),
      );
      if (response.data.isEmpty) {
        return null;
      }

      final image = response.data.first;
      final imageUrl = image.url;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return VisualExplanationImage(imageUrl: imageUrl);
      }

      final encoded = image.b64Json;
      if (encoded == null || encoded.isEmpty) {
        return null;
      }

      try {
        final bytes = base64Decode(encoded);
        return VisualExplanationImage(imageBytes: bytes);
      } catch (error, stackTrace) {
        debugPrint('Failed to decode visual aid: $error\n$stackTrace');
        return null;
      }
    } catch (error, stackTrace) {
      debugPrint('DALL-E generation failed: $error\n$stackTrace');
      return null;
    }
  }

  Future<VisualExplanationResult> createVisualExplanation({
    required String topic,
    required int difficulty,
    required String learnerName,
    bool requestImage = false,
    String? imageFocus,
    String? baseExplanation,
  }) async {
    final description = await _buildVisualDescription(
      topic: topic,
      difficulty: difficulty,
      learnerName: learnerName,
      baseExplanation: baseExplanation,
    );

    final imageTask = requestImage
        ? generateVisualAid(
            topic: topic,
            focus: imageFocus ?? topic,
            difficulty: difficulty,
          )
        : null;

    return VisualExplanationResult(
      description: description,
      imageTask: imageTask,
    );
  }

  Future<String> _buildVisualDescription({
    required String topic,
    required int difficulty,
    required String learnerName,
    String? baseExplanation,
  }) async {
    final client = _clientOrNull;
    const baseFormat =
        '## 개념 깊이 보기\n'
        '- 정의: 이 개념이 무엇인지 쉬운 말로 설명하고, 필요하면 기호나 공식도 함께 보여줄게\n'
        '- 핵심 규칙: 꼭 기억해야 할 규칙이나 공식을 2~4줄로 정리할게\n'
        '- 단계별 풀이법: 문제를 풀 때 따라갈 수 있는 순서를 3~6단계로 알려줄게\n'
        '- 흔한 실수: 자주 틀리는 부분과 올바르게 이해하는 방법을 설명할게\n'
        '- 예시: 간단한 예제 1~2개와 풀이 과정, 실생활에서 어떻게 쓰이는지 보여줄게\n'
        '- 이해도 체크: 스스로 이해했는지 확인할 수 있는 질문 3가지';
    final difficultyGuidance = difficulty < 3
        ? '난이도 $difficulty 단계에 맞춰 따뜻하고 쉬운 한국어를 사용하세요. 과일, 장난감, 블록 같은 친숙한 사물을 활용해 세기/묶기/비교를 자연스럽게 연결해 주세요. 학습자에게 직접 말하듯이 "너는", "네가" 같은 표현을 사용하세요.'
        : '난이도 $difficulty 단계에 맞춰 간결하고 명확한 한국어를 사용하세요. 난이도가 높을수록 더 전문적인 용어와 심화 개념을 포함하세요. 학습자에게 직접 설명하듯이 "당신은", "당신이", 또는 친근하게 "너는", "네가" 같은 표현을 사용하세요.';
    final baseInfo =
        (baseExplanation != null && baseExplanation.trim().isNotEmpty)
        ? '\n\n[이미 제공된 기본 설명]\n$baseExplanation\n\n이 설명보다 더 깊이 있게 확장하세요. 같은 문장을 반복하지 말고, 누락된 정의/공식/절차/흔한 실수/예시/체크리스트를 채워 넣으세요.'
        : '';
    final formatHint = '$baseFormat\n\n지침: $difficultyGuidance$baseInfo';
    final userPrompt =
        '주제: $topic\n학습자 이름: $learnerName\n난이도: $difficulty 단계\n위 형식을 그대로 따르고, 반드시 한국어로 작성하세요. 학습자에게 직접 설명하는 방식으로 작성하세요.';

    if (client == null) {
      return _visualFallbackDescription(topic, difficulty);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '당신은 MathMind이며, 학습자에게 직접 말하듯이 수학 개념을 설명하는 친절한 튜터입니다. '
                  '모든 응답은 100% 한국어로 작성하세요. 영어 표현이 섞이지 않도록 주의하세요. '
                  '학습자에게 직접 설명하는 방식으로 작성하세요. 예: "너는 이렇게 풀 수 있어", "당신은 이 공식을 사용하면 돼" 등. '
                  '제3자에게 지시하는 표현("~해 주세요", "~알려 주세요")은 사용하지 마세요.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$formatHint\n\n$userPrompt',
              ),
            ),
          ],
        ),
      );

      final message = response.choices.first.message;
      final output = message.maybeMap(
        assistant: (assistant) => assistant.content,
        orElse: () => null,
      );
      if (output == null || output.trim().isEmpty) {
        return _visualFallbackDescription(topic, difficulty);
      }
      return output.trim();
    } catch (error, stackTrace) {
      debugPrint('Failed to build visual description: $error\n$stackTrace');
      return _visualFallbackDescription(topic, difficulty);
    }
  }

  String _visualFallbackDescription(String topic, int difficulty) {
    return '## 개념 깊이 보기: $topic (난이도 $difficulty 단계)\n\n'
        '- 정의: 핵심 용어를 쉬운 말로 설명할게\n'
        '- 핵심 규칙: 꼭 알아야 할 공식이나 규칙을 정리해 줄게\n'
        '- 단계별 풀이법: 문제 풀 때 따라갈 순서를 알려줄게\n'
        '- 흔한 실수: 자주 하는 실수와 올바른 방법을 설명할게\n'
        '- 예시: 간단한 예제와 풀이, 실생활에서 어떻게 쓰이는지 보여줄게\n'
        '- 이해도 체크: 스스로 확인할 수 있는 질문 3개';
  }

  String _fallbackExplanation(String topic, int difficulty) {
    return '함께 $topic을(를) 알아볼까요? 난이도 $difficulty 단계에 맞춰 아주 쉽게 핵심 아이디어를 이야기해 볼게요.';
  }

  String _fallbackDetectedConcept(String problemStatement) {
    if (problemStatement.toLowerCase().contains('fraction')) {
      return '분수 연산';
    }
    if (problemStatement.toLowerCase().contains('triangle')) {
      return '삼각형 기하';
    }
    return '일반 수학 연습';
  }

  List<ConceptBreakdown> _fallbackConceptBreakdown(String problemStatement) {
    final concept = _fallbackDetectedConcept(problemStatement);
    final summary =
        '이 문제를 풀 때는 "$concept" 개념이 중요해요. 이 개념의 기본 규칙과 예시를 다시 확인해 보세요.';
    return [ConceptBreakdown(name: concept, summary: summary)];
  }

  int heuristicScore(
    String learnerExplanation, {
    List<String>? requiredConcepts,
  }) {
    if (learnerExplanation.trim().isEmpty) {
      return 0;
    }
    final lengthScore = min(learnerExplanation.length, 400) / 4;
    int score = lengthScore.round().clamp(30, 85);
    // If required concepts are present in the explanation, boost score
    if (requiredConcepts != null && requiredConcepts.isNotEmpty) {
      int found = 0;
      final lower = learnerExplanation.toLowerCase();
      for (final concept in requiredConcepts) {
        if (lower.contains(concept.toLowerCase())) {
          found++;
        }
      }
      // If all required concepts are mentioned, boost to 90+
      if (found == requiredConcepts.length) {
        score = max(score, 90);
      } else if (found > 0) {
        score = max(score, 75);
      }
    }
    return score;
  }

  // Heuristic conceptual scoring aligned with recall/application/integration
  int heuristicScoreConceptual(
    String learnerExplanation, {
    String? topic,
    String? expectedConcept,
  }) {
    final h = _heuristicConceptualComponents(
      learnerExplanation,
      topic: topic,
      expectedConcept: expectedConcept,
    );
    return h.total;
  }

  _ConceptualHeuristic _heuristicConceptualComponents(
    String learnerExplanation, {
    String? topic,
    String? expectedConcept,
  }) {
    if (learnerExplanation.trim().isEmpty) {
      return const _ConceptualHeuristic(recall: 0, application: 0, integration: 0, total: 0);
    }
    final text = learnerExplanation.toLowerCase();

    final recallTerms = <String>{};
    if (topic != null) recallTerms.addAll(topic.toLowerCase().split(RegExp(r'[^a-z0-9가-힣]+')).where((e) => e.length >= 2));
    if (expectedConcept != null) recallTerms.addAll(expectedConcept.toLowerCase().split(RegExp(r'[^a-z0-9가-힣]+')).where((e) => e.length >= 2));
    recallTerms.addAll(['정의','공식','법칙','정리','개념','조건']);
    final recallHits = recallTerms.where((w) => text.contains(w)).length;
    final recall = (recallHits >= 3) ? 85 : (recallHits == 2 ? 70 : (recallHits == 1 ? 55 : 35));

    final hasStepMarkers = RegExp(r'(첫째|둘째|셋째|먼저|다음|그리고|마지막|1\)|2\)|3\))').hasMatch(learnerExplanation);
    final hasEquation = RegExp(r'[=><]|\\[a-zA-Z]+|\d+\s*[a-zA-Z]').hasMatch(learnerExplanation);
    final hasProcedureVerb = RegExp(r'(대입|정리|계산|유도|변형|미분|적분|대수|대칭|치환|전개|인수분해)').hasMatch(learnerExplanation);
    final appScore = [hasStepMarkers, hasEquation, hasProcedureVerb].where((e) => e).length;
    final application = appScore == 3 ? 90 : appScore == 2 ? 75 : appScore == 1 ? 60 : 35;

    final hasRelation = RegExp(r'(따라서|그러므로|왜냐하면|때문에|즉|그래서|연결|관계|비례|반비례|동치|충분조건|필요조건)').hasMatch(learnerExplanation);
    final mentionsTwoConcepts = RegExp(r'(\w+)\s*(과|와|및)\s*(\w+)').hasMatch(learnerExplanation);
    final integration = (hasRelation && mentionsTwoConcepts) ? 85 : (hasRelation || mentionsTwoConcepts) ? 70 : 40;

    final total = ((recall + application + integration) / 3).round().clamp(0, 100);
    return _ConceptualHeuristic(recall: recall, application: application, integration: integration, total: total);
  }

  int _weightedTotal(int recall, int application, int integration, {int? difficulty}) {
    if (difficulty == null) {
      return ((recall + application + integration) / 3).round().clamp(0, 100);
    }
    final d = difficulty.clamp(0, 9);
    final t = d / 9.0; // 0(쉬움) -> 1(어려움)
    final wRecall = 0.5 - 0.3 * t;      // 0.5 -> 0.2
    final wIntegration = 0.2 + 0.3 * t; // 0.2 -> 0.5
    final wApplication = 1.0 - wRecall - wIntegration; // ~0.3 유지
    final total = (recall * wRecall + application * wApplication + integration * wIntegration).round();
    return total.clamp(0, 100);
  }

  String _fallbackConceptualFeedback(int recall, int application, int integration) {
    String weakest;
    final minVal = [recall, application, integration].reduce((a, b) => a < b ? a : b);
    if (minVal == recall) {
      weakest = '개념 인식(정의/핵심 용어)';
    } else if (minVal == application) {
      weakest = '개념 적용(절차/공식 사용)';
    } else {
      weakest = '개념 연결(이유/관계 설명)';
    }
    return '잘하고 있어요! 특히 "$weakest" 부분을 한 줄로 정리해 보면 더 좋아요.';
  }
}

class ConceptualEvaluation {
  const ConceptualEvaluation({
    required this.score,
    required this.recall,
    required this.application,
    required this.integration,
    required this.feedback,
  });

  final int score; // 0-100
  final int recall; // 0-100
  final int application; // 0-100
  final int integration; // 0-100
  final String feedback;
}

class _ConceptualHeuristic {
  const _ConceptualHeuristic({
    required this.recall,
    required this.application,
    required this.integration,
    required this.total,
  });

  final int recall;
  final int application;
  final int integration;
  final int total;
}

class ConceptBreakdown {
  const ConceptBreakdown({required this.name, this.summary = ''});

  final String name;
  final String summary;

  factory ConceptBreakdown.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String?)?.trim() ?? '';
    final rawSummary = (json['summary'] as String?)?.trim() ?? '';
    return ConceptBreakdown(
      name: rawName.isEmpty ? '관련 개념' : rawName,
      summary: rawSummary,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConceptBreakdown &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          summary == other.summary;

  @override
  int get hashCode => Object.hash(name, summary);
}

class VisualExplanationImage {
  const VisualExplanationImage({this.imageBytes, this.imageUrl});

  final Uint8List? imageBytes;
  final String? imageUrl;

  bool get hasData => imageBytes != null || imageUrl != null;
}

class VisualExplanationResult {
  const VisualExplanationResult({
    required this.description,
    this.imageBytes,
    this.imageUrl,
    this.imageTask,
  });

  final String description;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final Future<VisualExplanationImage?>? imageTask;

  bool get hasImage => imageBytes != null || imageUrl != null;
  bool get canRequestAsyncImage => imageTask != null;
}

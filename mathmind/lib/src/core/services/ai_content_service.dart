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
    final prompt =
        '수학 개념 "$topic"을(를) 난이도 $difficulty 단계에 맞춰 설명해 주세요. '
        '난이도 0은 아주 쉬운 설명(초등 저학년 수준, 그림/비유/일상 예시 위주), 난이도 9는 고급 설명(수식, 정의, 증명, 심화 개념 포함)입니다. '
        '난이도가 높아질수록 더 전문적이고 깊이 있게, 낮을수록 더 쉽고 직관적으로 설명해 주세요. '
        '친근한 말투와 짧은 문단을 사용하고, 아래 구조를 따라 작성해 주세요:\n'
        '1) 핵심 아이디어 한 문단\n'
        '2) 예시 또는 직관적 설명 한 문단\n'
        '3) 따라 해 볼 간단한 연습 문제(정답 포함)';

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
                '$prompt 학습자의 이름은 $learnerName 입니다.',
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

  Future<int> evaluateUnderstanding({
    required String topic,
    required String expectedConcept,
    required String learnerExplanation,
  }) async {
    final client = _clientOrNull;
    if (client == null) {
      return _heuristicScore(learnerExplanation);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          responseFormat: const ResponseFormat.jsonSchema(
            jsonSchema: JsonSchemaObject(
              name: 'understanding',
              schema: {
                'type': 'object',
                'properties': {
                  'score': {'type': 'integer', 'minimum': 0, 'maximum': 100},
                  'feedback': {'type': 'string'},
                },
                'required': ['score', 'feedback'],
              },
            ),
          ),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '당신은 학생이 수학 주제를 얼마나 이해했는지 평가합니다. '
                  'score(0-100)와 feedback 필드를 포함한 JSON만 반환하세요. '
                  'feedback은 한국어로 짧고 친근하게 작성하세요.',
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
        return _heuristicScore(learnerExplanation);
      }

      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      return (decoded['score'] as num?)?.clamp(0, 100).round() ??
          _heuristicScore(learnerExplanation);
    } catch (error, stackTrace) {
      debugPrint('OpenAI evaluation failed: $error\n$stackTrace');
      return _heuristicScore(learnerExplanation);
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

  int _heuristicScore(String learnerExplanation) {
    if (learnerExplanation.trim().isEmpty) {
      return 0;
    }
    final lengthScore = min(learnerExplanation.length, 400) / 4;
    return lengthScore.round().clamp(30, 85);
  }
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

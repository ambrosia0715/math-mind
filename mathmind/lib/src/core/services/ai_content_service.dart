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
    required int age,
    required String learnerName,
    bool includeVisualPrompt = false,
  }) async {
    final prompt =
        '수학 개념 "$topic"을(를) $age세 학습자가 이해할 수 있도록 단계별로 정리해 주세요. '
        '어려운 전문 용어가 필요한 경우에는 반드시 짧게 풀이 표현을 덧붙이고, 가능한 한 $age세 학습자가 일상에서 쓰는 쉬운 단어를 사용해 주세요. '
        '친근한 말투와 짧은 문단을 사용하고, 아래 구조를 따라 작성해 주세요:\n'
        '1) 핵심 아이디어 한 문단\n'
        '2) 예시 또는 직관적 설명 한 문단\n'
        '3) 따라 해 볼 간단한 연습 문제(정답 포함)';

    final client = _clientOrNull;
    if (client == null) {
      return _fallbackExplanation(topic, age);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  '당신은 MathMind이며, 학습자의 나이에 맞춰 설명해 주는 격려하는 수학 튜터입니다. '
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
        return _fallbackExplanation(topic, age);
      }
      return output.trim();
    } catch (error, stackTrace) {
      debugPrint('Failed to call OpenAI: $error\n$stackTrace');
      return _fallbackExplanation(topic, age);
    }
  }

  Future<List<ConceptBreakdown>> analyzeProblemConcepts({
    required String problem,
    required int age,
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
                '문제: $problem\n학습자 나이: $age세',
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
  }) async {
    final client = _clientOrNull;
    if (client == null) {
      return null;
    }

    try {
      final response = await client.createImage(
        request: CreateImageRequest(
          prompt:
              'Create a clear, student-friendly diagram that explains $topic with focus on $focus.',
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
    required int age,
    required String learnerName,
    bool requestImage = false,
    String? imageFocus,
  }) async {
    final description = await _buildVisualDescription(
      topic: topic,
      age: age,
      learnerName: learnerName,
    );

    final imageTask = requestImage
        ? generateVisualAid(
            topic: topic,
            focus: imageFocus ?? topic,
          )
        : null;

    return VisualExplanationResult(
      description: description,
      imageTask: imageTask,
    );
  }

  Future<String> _buildVisualDescription({
    required String topic,
    required int age,
    required String learnerName,
  }) async {
    final client = _clientOrNull;
    const formatHint = '## Concept summary\n- Summarise the core idea in two short sentences\n\n'
        '## Visual ideas\n- Visual 1: describe a chart, diagram, or drawing the learner can sketch\n'
        '- Visual 2: describe a real-life story or scene that matches the concept\n\n'
        '## Drawing tips\n- Provide simple steps the learner can follow with pencil and colours';
    final userPrompt =
        'Topic: $topic\nLearner name: $learnerName\nLearner age: $age years old\nUse the format above and respond in Korean.';

    if (client == null) {
      return _visualFallbackDescription(topic, age);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are MathMind, a supportive maths tutor who adds visual storytelling to explanations. '
                  'Use clear Korean language suited to the learner age. When presenting visual ideas, mention the shapes or layout that should appear.',
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
        return _visualFallbackDescription(topic, age);
      }
      return output.trim();
    } catch (error, stackTrace) {
      debugPrint('Failed to build visual description: $error\n$stackTrace');
      return _visualFallbackDescription(topic, age);
    }
  }

  String _visualFallbackDescription(String topic, int age) {
    return 'Visual explanation guide for $topic (age ${age.toString()}).\n\n'
        '## Concept summary\n- Highlight the main idea in two friendly sentences.\n\n'
        '## Visual ideas\n- Visual 1: sketch the concept with simple shapes or a chart.\n'
        '- Visual 2: draw a real-life scenario that matches the idea.\n\n'
        '## Drawing tips\n- Use pencils and colours to label each step.\n'
        '- Write key words next to the drawings to remember them.';
  }

  String _fallbackExplanation(String topic, int age) {
    return '함께 $topic을(를) 알아볼까요? $age세 친구가 쓰는 쉬운 말로 핵심 아이디어를 이야기해 보면...';
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
  const VisualExplanationImage({
    this.imageBytes,
    this.imageUrl,
  });

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

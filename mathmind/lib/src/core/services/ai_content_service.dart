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
    required int grade,
    required String learnerName,
    bool includeVisualPrompt = false,
  }) async {
    final prompt =
        'Explain the math concept "$topic" so that a learner around grade $grade can understand it. '
        'Use friendly tone, short paragraphs, and include a quick practice question.';

    final client = _clientOrNull;
    if (client == null) {
      return _fallbackExplanation(topic, grade);
    }

    try {
      final response = await client.createChatCompletion(
        request: CreateChatCompletionRequest(
          model: ChatCompletionModel.modelId('gpt-4o-mini'),
          messages: [
            ChatCompletionMessage.system(
              content:
                  'You are MathMind, an encouraging math tutor who adapts explanations to the user age.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                '$prompt The learner name is $learnerName.',
              ),
            ),
          ],
        ),
      );

      final message = response.choices.first.message;
      return message.maybeMap(
        assistant: (assistant) =>
            assistant.content ?? _fallbackExplanation(topic, grade),
        orElse: () => _fallbackExplanation(topic, grade),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to call OpenAI: $error\n$stackTrace');
      return _fallbackExplanation(topic, grade);
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
                  'You grade how well a student understands a math topic. Return JSON containing score (0-100) and feedback.',
            ),
            ChatCompletionMessage.user(
              content: ChatCompletionUserMessageContent.string(
                'Topic: $topic\nExpected concept: $expectedConcept\nStudent explanation: $learnerExplanation',
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
                  'Return the core math concept addressed by the user problem in a short noun phrase. '
                  'Examples: "fractions addition", "Pythagorean theorem", "quadratic equations".',
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

  Future<String?> generateVisualAid({
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
      return image.url ?? image.b64Json;
    } catch (error, stackTrace) {
      debugPrint('DALL·E generation failed: $error\n$stackTrace');
      return null;
    }
  }

  String _fallbackExplanation(String topic, int grade) {
    return 'Let\'s explore $topic together! For a typical grade $grade student, the key idea is...';
  }

  String _fallbackDetectedConcept(String problemStatement) {
    if (problemStatement.toLowerCase().contains('fraction')) {
      return 'fraction operations';
    }
    if (problemStatement.toLowerCase().contains('triangle')) {
      return 'triangle geometry';
    }
    return 'general math practice';
  }

  int _heuristicScore(String learnerExplanation) {
    if (learnerExplanation.trim().isEmpty) {
      return 0;
    }
    final lengthScore = min(learnerExplanation.length, 400) / 4;
    return lengthScore.round().clamp(30, 85);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  SpeechService({FlutterTts? tts, SpeechToText? speechToText})
    : _tts = tts ?? FlutterTts(),
      _speechToText = speechToText ?? SpeechToText() {
    _tts.setCompletionHandler(() {
      _onTtsComplete?.call();
    });
  }

  final FlutterTts _tts;
  final SpeechToText _speechToText;
  VoidCallback? _onTtsComplete;

  void setCompletionHandler(VoidCallback? handler) {
    _onTtsComplete = handler;
  }

  /// Clean text for TTS by removing LaTeX, markdown, and special formatting
  String _cleanTextForSpeech(String text) {
    var cleaned = text;

    // Remove LaTeX inline math: \( ... \) or $ ... $
    cleaned = cleaned.replaceAll(RegExp(r'\\\(.*?\\\)'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'\$.*?\$'), ' ');

    // Remove LaTeX commands like \alpha, \beta, \times, etc.
    // Replace common math symbols with Korean
    cleaned = cleaned.replaceAll(RegExp(r'\\times'), '곱하기');
    cleaned = cleaned.replaceAll(RegExp(r'\\div'), '나누기');
    cleaned = cleaned.replaceAll(RegExp(r'\\pm'), '플러스 마이너스');
    cleaned = cleaned.replaceAll(RegExp(r'\\le'), '이하');
    cleaned = cleaned.replaceAll(RegExp(r'\\ge'), '이상');
    cleaned = cleaned.replaceAll(RegExp(r'\\ne'), '같지 않다');
    cleaned = cleaned.replaceAll(RegExp(r'\\approx'), '약');
    cleaned = cleaned.replaceAll(RegExp(r'\\sqrt'), '제곱근');
    cleaned = cleaned.replaceAll(RegExp(r'\\frac'), '분수');
    cleaned = cleaned.replaceAll(RegExp(r'\\pi'), '파이');
    cleaned = cleaned.replaceAll(RegExp(r'\\alpha'), '알파');
    cleaned = cleaned.replaceAll(RegExp(r'\\beta'), '베타');
    cleaned = cleaned.replaceAll(RegExp(r'\\theta'), '세타');

    // Remove other LaTeX commands (backslash followed by letters)
    cleaned = cleaned.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');

    // Remove markdown bold/italic: **text** or *text* or __text__ or _text_
    cleaned = cleaned.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'\*(.*?)\*'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'__(.*?)__'), r'\1');
    cleaned = cleaned.replaceAll(RegExp(r'_(.*?)_'), r'\1');

    // Remove markdown headers: ## or ###
    cleaned = cleaned.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');

    // Remove extra backslashes
    cleaned = cleaned.replaceAll(r'\', '');

    // Remove curly braces used in LaTeX
    cleaned = cleaned.replaceAll('{', '');
    cleaned = cleaned.replaceAll('}', '');

    // Clean up multiple spaces
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    // Trim
    cleaned = cleaned.trim();

    return cleaned;
  }

  Future<bool> ensureSpeechReady() async {
    if (_speechToText.isAvailable) {
      return true;
    }
    final available = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech init error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    return available;
  }

  Future<void> speak(String text) async {
    final cleanedText = _cleanTextForSpeech(text);
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.9);
    await _tts.speak(cleanedText);
  }

  Future<void> speakWithAgeAppropriateVoice(String text, int difficulty) async {
    final cleanedText = _cleanTextForSpeech(text);
    await _tts.setLanguage('ko-KR');

    // Map difficulty (0-9) to appropriate voice settings
    if (difficulty <= 3) {
      // Easiest levels (0-3): higher pitch, slower speed
      await _tts.setPitch(1.2);
      await _tts.setSpeechRate(0.8);
    } else if (difficulty <= 6) {
      // Medium levels (4-6): medium pitch and speed
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.9);
    } else {
      // Advanced levels (7-9): normal pitch, slightly faster
      await _tts.setPitch(0.95);
      await _tts.setSpeechRate(1.0);
    }

    await _tts.speak(cleanedText);
  }

  Future<void> stopSpeaking() => _tts.stop();

  Future<bool> listen({
    void Function(String partial)? onPartialResult,
    void Function(String finalResult)? onFinalResult,
  }) async {
    final ready = await ensureSpeechReady();
    if (!ready) {
      return false;
    }

    await _speechToText.listen(
      onResult: (result) {
        if (result.finalResult) {
          onFinalResult?.call(result.recognizedWords);
        } else {
          onPartialResult?.call(result.recognizedWords);
        }
      },
      pauseFor: const Duration(seconds: 4),
      localeId: 'ko_KR',
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );

    return _speechToText.isListening;
  }

  Future<void> stopListening() => _speechToText.stop();
}

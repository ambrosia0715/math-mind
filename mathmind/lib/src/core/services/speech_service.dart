import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechService {
  SpeechService({FlutterTts? tts, SpeechToText? speechToText})
    : _tts = tts ?? FlutterTts(),
      _speechToText = speechToText ?? SpeechToText();

  final FlutterTts _tts;
  final SpeechToText _speechToText;

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
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.9);
    await _tts.speak(text);
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
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
    );

    return _speechToText.isListening;
  }

  Future<void> stopListening() => _speechToText.stop();
}

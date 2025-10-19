import 'dart:async';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MathExpressionService {
  MathExpressionService() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;

  Future<String?> recognizeFromPath(String path) async {
    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognized = await _recognizer.processImage(inputImage);
    final buffer = StringBuffer();
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        buffer.write(line.text);
        buffer.write(' ');
      }
    }
    final text = buffer.toString().trim();
    if (text.isEmpty) {
      return null;
    }
    return text.replaceAll('\n', ' ');
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

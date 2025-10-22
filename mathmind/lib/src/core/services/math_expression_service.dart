import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Helper class to store text elements with their positions
class _TextElement {
  const _TextElement({required this.text, required this.boundingBox});

  final String text;
  final Rect boundingBox;
}

class MathExpressionService {
  MathExpressionService() : _recognizer = kIsWeb ? null : TextRecognizer();

  final TextRecognizer? _recognizer;

  Future<String?> recognizeFromPath(String path) async {
    // Web platform doesn't support ML Kit text recognition
    if (kIsWeb) {
      return _recognizeFromPathWeb(path);
    }

    // Native platforms (Android, iOS)
    if (_recognizer == null) {
      throw Exception('Text recognizer not available');
    }

    final inputImage = InputImage.fromFilePath(path);
    final RecognizedText recognized = await _recognizer.processImage(
      inputImage,
    );

    // Collect all text elements with their positions for better ordering
    final List<_TextElement> elements = [];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          elements.add(
            _TextElement(text: element.text, boundingBox: element.boundingBox),
          );
        }
      }
    }

    if (elements.isEmpty) {
      return null;
    }

    // Sort elements by position (top to bottom, left to right)
    elements.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;

      // If they're on roughly the same line (within 20 pixels)
      if ((aTop - bTop).abs() < 20) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return aTop.compareTo(bTop);
    });

    // Combine text with better spacing and math-aware cleanup
    final buffer = StringBuffer();
    for (int i = 0; i < elements.length; i++) {
      final element = elements[i];
      final cleanText = _cleanMathText(element.text);

      if (cleanText.isNotEmpty) {
        if (buffer.isNotEmpty) {
          // Add space between elements, but be smart about math symbols
          if (!_shouldSkipSpace(buffer.toString(), cleanText)) {
            buffer.write(' ');
          }
        }
        buffer.write(cleanText);
      }
    }

    final finalText = buffer.toString().trim();
    return finalText.isEmpty ? null : finalText;
  }

  /// Clean up common OCR mistakes in mathematical text
  String _cleanMathText(String text) {
    var cleaned = text;

    // Common OCR mistakes for math symbols
    cleaned = cleaned.replaceAll('×', '*');
    cleaned = cleaned.replaceAll('÷', '/');
    cleaned = cleaned.replaceAll('—', '-');
    cleaned = cleaned.replaceAll('–', '-');

    // Fix common letter/number confusions
    cleaned = cleaned.replaceAll(RegExp(r'\bl\b'), '1'); // lowercase L to 1
    cleaned = cleaned.replaceAll(RegExp(r'\bO\b'), '0'); // uppercase O to 0
    cleaned = cleaned.replaceAll(RegExp(r'\bI\b'), '1'); // uppercase I to 1

    // Clean up extra spaces around operators
    cleaned = cleaned.replaceAll(RegExp(r'\s*([+\-*/=<>])\s*'), r'$1');

    return cleaned.trim();
  }

  /// Determine if we should skip adding a space between two text segments
  bool _shouldSkipSpace(String before, String after) {
    if (before.isEmpty || after.isEmpty) return true;

    final lastChar = before[before.length - 1];
    final firstChar = after[0];

    // Don't add space around operators and parentheses
    const operators = '+-*/=<>()[]{}';

    return operators.contains(lastChar) || operators.contains(firstChar);
  }

  /// Web-specific text recognition (placeholder implementation)
  Future<String?> _recognizeFromPathWeb(String path) async {
    // For web, we'll return a helpful message for now
    // In a production app, you might want to integrate with Tesseract.js or similar
    throw UnsupportedError(
      'Text recognition from images is not supported on web platform. '
      'Please use the mobile app for this feature.',
    );
  }

  Future<void> dispose() async {
    await _recognizer?.close();
  }
}

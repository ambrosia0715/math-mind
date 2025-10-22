import 'package:flutter_test/flutter_test.dart';
import 'package:mathmind/src/core/services/math_expression_service.dart';

void main() {
  group('MathExpressionService Text Cleaning Tests', () {
    late MathExpressionService service;

    setUp(() {
      service = MathExpressionService();
    });

    test('should clean common OCR noise characters', () {
      // Test noise removal patterns
      const noisyText = 'x|2 + y\\3 - a"b + c`d + e~f';
      final result = service.testCleanMathText(noisyText);

      // Should remove |, \, ", `, ~ characters but preserve valid math
      expect(result, equals('x2 + y3 - ab + cd + ef'));
    });

    test('should fix common OCR letter/number confusions', () {
      const confusedText = 'S + O + I + l + Z';
      final result = service.testCleanMathText(confusedText);

      // Should convert S→5, O→0, I→1, l→1, Z→2
      expect(result, equals('5 + 0 + 1 + 1 + 2'));
    });

    test('should handle complex mathematical expressions', () {
      const mathText = 'x^2 + y^3 = S*O + I/l - Z|2';
      final result = service.testCleanMathText(mathText);

      // Should clean noise and fix confusions with proper spacing
      expect(result, equals('x^2 + y^3 = 5 * 0 + 1 / 1 - 22'));
    });

    test('should preserve valid mathematical symbols', () {
      const validMath = 'x + y - z * w / v = 0';
      final result = service.testCleanMathText(validMath);

      // Should not change valid mathematical expression
      expect(result, equals('x + y - z * w / v = 0'));
    });

    test('should handle mixed noise and valid content', () {
      const mixedText = 'x"2 + |y - z\\w = S.O';
      final result = service.testCleanMathText(mixedText);

      // Should remove noise and fix confusions while preserving structure
      expect(result, equals('x2 + y - zw = 5.0'));
    });
  });
}

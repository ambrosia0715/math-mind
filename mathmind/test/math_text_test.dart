import 'package:flutter_test/flutter_test.dart';
import 'package:mathmind/src/core/utils/math_text.dart';

void main() {
  group('cleanMathForDisplay', () {
    test('preserves lambda in internal division formula', () {
      const input = r"\\lambda:(1-\\lambda)";
      final out = cleanMathForDisplay(input);
      expect(out.contains('λ'), isTrue);
      expect(RegExp(r'λ:\(1\s*-\s*λ\)').hasMatch(out), isTrue);
    });

    test('renders inline latex with lambda', () {
      const input = r"$x_1 + \\lambda (x_2 - x_1)$";
      final out = cleanMathForDisplay(input);
      expect(out.contains('λ'), isTrue);
      expect(out.contains('x₁'), isTrue);
    });
  });
}

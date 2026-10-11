import 'models.dart';

class MathEvaluator {
  /// Evaluates an arithmetic expression adhering strictly to PEMDAS/BODMAS.
  /// Multiplication and division have higher precedence than addition and subtraction.
  ///
  /// Returns `null` if:
  /// - Division by zero occurs
  /// - Non-integer division occurs (remainder != 0)
  /// - Intermediate or final result is negative (unless explicitly allowed)
  static int? evaluateTokens(
    List<int> numbers,
    List<Op> operators, {
    bool allowNegative = false,
  }) {
    if (numbers.length != operators.length + 1 || numbers.isEmpty) {
      return null;
    }

    // Pass 1: Handle Multiplication and Division (left-to-right)
    final reducedNums = <int>[numbers[0]];
    final reducedOps = <Op>[];

    for (int i = 0; i < operators.length; i++) {
      final op = operators[i];
      final nextNum = numbers[i + 1];

      if (op == Op.mul) {
        final prev = reducedNums.removeLast();
        reducedNums.add(prev * nextNum);
      } else if (op == Op.div) {
        if (nextNum == 0) return null;
        final prev = reducedNums.removeLast();
        if (prev % nextNum != 0) return null; // Only exact whole integer divisions
        reducedNums.add(prev ~/ nextNum);
      } else {
        reducedOps.add(op);
        reducedNums.add(nextNum);
      }
    }

    // Pass 2: Handle Addition and Subtraction (left-to-right)
    int result = reducedNums[0];
    for (int i = 0; i < reducedOps.length; i++) {
      final op = reducedOps[i];
      final next = reducedNums[i + 1];

      if (op == Op.add) {
        result += next;
      } else if (op == Op.sub) {
        result -= next;
        if (!allowNegative && result < 0) {
          return null; // Reject negative intermediate totals
        }
      }
    }

    if (!allowNegative && result < 0) return null;
    return result;
  }

  /// Verifies whether the provided numbers and operators match the expected result.
  static bool isSatisfied(
    List<int> operands,
    List<Op> operators,
    int expectedResult, {
    bool allowNegative = false,
  }) {
    final computed = evaluateTokens(operands, operators, allowNegative: allowNegative);
    return computed != null && computed == expectedResult;
  }

  /// Formats equation as a readable string, e.g. "3 + 4 = 7" or "2 + 3 × 4 = 14"
  static String formatEquation(List<int> operands, List<Op> operators, int result) {
    if (operands.length != operators.length + 1) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < operands.length; i++) {
      buffer.write(operands[i]);
      if (i < operators.length) {
        buffer.write(' ${operators[i].symbol} ');
      }
    }
    buffer.write(' = $result');
    return buffer.toString();
  }
}

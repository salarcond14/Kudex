import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kudex/main.dart';

void main() {
  test('DrawnLine data can be restored from JSON', () {
    final line = DrawnLine(
      [const Offset(1, 2), const Offset(3, 4)],
      const Color(0xFFFF7A7A),
      3,
      isEraser: true,
    );

    final restored = DrawnLine.fromJson(line.toJson());

    expect(restored.path, line.path);
    expect(restored.color, line.color);
    expect(restored.width, line.width);
    expect(restored.isEraser, isTrue);
  });
}

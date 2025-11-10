import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:tremor_test_fe/utils/spiral_analyzer.dart';
import 'package:tremor_test_fe/utils/spiral_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiralAnalyzer', () {
    test('produces low mean error for perfect baseline drawing', () {
      const canvasSize = 300.0;
      const numPoints = 500;
      const samplingFrequency = 50.0; // Hz

      final refPoints = SpiralGenerator.getSpiralPoints(canvasSize, numPoints);
      final analyzer = SpiralAnalyzer(fs: samplingFrequency);

      final actualTimeSeconds = numPoints / samplingFrequency;

      final result = analyzer.analyze(
        refPoints: refPoints,
        userRawPoints: List<Offset>.from(refPoints),
        actualTime: actualTimeSeconds,
        actualTremor: 0.0,
      );

      expect(result.meanError, lessThan(1.0),
          reason: 'Perfect drawing should stay within 1px mean error');
      expect(result.judgment,
          equals('⭕ 정상 범위: 통계적 유의미한 차이 없음'));
    });
  });
}


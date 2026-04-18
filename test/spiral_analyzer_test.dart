import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:tremor_test_fe/models/test_result.dart';
import 'package:tremor_test_fe/utils/spiral_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SpiralAnalyzer', () {
    test('produces low mean error for perfect baseline drawing', () {
      const numSamples = 400;
      const double dtMs = 10.0; // 100 Hz sampling
      final analyzer = const SpiralAnalyzer(lowPassCutoffHz: 50.0);

      final perfectPoints = <DrawingPoint>[];
      final noisyPoints = <DrawingPoint>[];
      final refPoints = <Offset>[];

      for (int i = 0; i < numSamples; i++) {
        final theta = i * 0.05;
        final radius = 8.0 * theta;
        final x = radius * math.cos(theta);
        final y = radius * math.sin(theta);
        refPoints.add(Offset(x, y));
        final timestamp = (i * dtMs).round();
        perfectPoints.add(
          DrawingPoint(
            x: x,
            y: y,
            normalizedX: 0.0,
            normalizedY: 0.0,
            timestamp: timestamp,
          ),
        );
        final noisyX = x + 2.0 * math.sin(i * 0.5);
        final noisyY = y + 2.0 * math.cos(i * 0.5);
        noisyPoints.add(
          DrawingPoint(
            x: noisyX,
            y: noisyY,
            normalizedX: 0.0,
            normalizedY: 0.0,
            timestamp: timestamp,
          ),
        );
      }

      final perfectResult = analyzer.analyze(
        refPoints: refPoints,
        drawingPoints: perfectPoints,
      );

      final noisyResult = analyzer.analyze(
        refPoints: refPoints,
        drawingPoints: noisyPoints,
      );

      expect(
        perfectResult.meanError,
        lessThanOrEqualTo(noisyResult.meanError),
        reason: 'Perfect spiral should score better than noisy spiral',
      );
    });
  });
}


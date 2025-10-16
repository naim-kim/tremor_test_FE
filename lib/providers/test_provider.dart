import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../models/test_result.dart';
import '../utils/fft_analyzer.dart';
import '../utils/spiral_generator.dart';

class TestProvider extends ChangeNotifier {
  final Box<TestResult> _resultsBox = Hive.box<TestResult>('test_results');
  final _uuid = const Uuid();

  List<TestResult> get allResults => _resultsBox.values.toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  TestResult? getLatestResult(TestType testType) {
    final filtered = _resultsBox.values
        .where((result) => result.testType == testType)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return filtered.isNotEmpty ? filtered.first : null;
  }

  List<TestResult> getResultsByType(TestType testType) {
    return _resultsBox.values
        .where((result) => result.testType == testType)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<TestResult> analyzeTest({
    required TestType testType,
    required List<DrawingPoint> points,
  }) async {
    // Perform FFT analysis
    final metrics = await FFTAnalyzer.analyze(points);

    // Calculate deviation from baseline for spiral test
    double deviation = 0;
    if (testType == TestType.spiral) {
      final baselinePoints = SpiralGenerator.getSpiralPoints(300, 500);
      deviation = FFTAnalyzer.calculateDeviationFromBaseline(
        points,
        baselinePoints,
      );
    }

    // Update metrics with deviation
    final updatedMetrics = TremorMetrics(
      frequency: metrics.frequency,
      amplitude: metrics.amplitude,
      deviationFromBaseline: deviation,
      testDuration: metrics.testDuration,
      averageSpeed: metrics.averageSpeed,
      mean: metrics.mean,
      std: metrics.std,
    );

    // Calculate overall score (0-100)
    final overallScore = _calculateOverallScore(updatedMetrics);

    // Determine result category
    final resultCategory = _determineResultCategory(overallScore);

    return TestResult(
      id: _uuid.v4(),
      userId: 'current_user', // Replace with actual user ID
      testType: testType,
      timestamp: DateTime.now(),
      drawingPoints: points,
      overallScore: overallScore,
      metrics: updatedMetrics,
      resultCategory: resultCategory,
    );
  }

  double _calculateOverallScore(TremorMetrics metrics) {
    // Scoring algorithm (placeholder - adjust based on research)
    // Lower is better for: frequency (if pathological), amplitude, deviation, duration
    // Higher is better for: controlled speed

    double score = 100.0;

    // Frequency scoring (pathological tremor usually 3-12 Hz)
    if (metrics.frequency >= 3 && metrics.frequency <= 12) {
      score -= (metrics.frequency / 12) * 20; // Max -20 points
    }

    // Amplitude scoring (higher amplitude = worse)
    final amplitudeScore = (metrics.amplitude / 10).clamp(0, 1) * 25;
    score -= amplitudeScore; // Max -25 points

    // Deviation from baseline (spiral test)
    if (metrics.deviationFromBaseline > 0) {
      final deviationScore =
          (metrics.deviationFromBaseline / 50).clamp(0, 1) * 25;
      score -= deviationScore; // Max -25 points
    }

    // Duration scoring (too fast or too slow is bad)
    // Ideal duration: 10-30 seconds
    if (metrics.testDuration < 10) {
      score -= ((10 - metrics.testDuration) / 10) * 15; // Too fast
    } else if (metrics.testDuration > 30) {
      score -= ((metrics.testDuration - 30) / 30).clamp(0, 1) * 15; // Too slow
    }

    // Speed scoring (very high tremor frequency affects this)
    final normalizedSpeed = (metrics.averageSpeed / 100).clamp(0, 1);
    if (normalizedSpeed > 0.8 || normalizedSpeed < 0.2) {
      score -= 15; // Abnormal speed
    }

    return score.clamp(0, 100);
  }

  String _determineResultCategory(double score) {
    // Thresholds (placeholder - adjust based on clinical data)
    if (score >= 85) {
      return '매우 좋음';
    } else if (score >= 70) {
      return '좋음';
    } else if (score >= 55) {
      return '보통';
    } else if (score >= 40) {
      return '주의 필요';
    } else {
      return '병원 방문 권장';
    }
  }

  Future<void> saveResult(TestResult result) async {
    await _resultsBox.put(result.id, result);
    notifyListeners();
  }

  Future<void> deleteResult(String id) async {
    await _resultsBox.delete(id);
    notifyListeners();
  }

  Future<void> clearAllResults() async {
    await _resultsBox.clear();
    notifyListeners();
  }

  // Export data as CSV for analysis
  String exportResultToCSV(TestResult result) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('x,y,normalizedX,normalizedY,timestamp');

    // Data points
    for (final point in result.drawingPoints) {
      buffer.writeln(
        '${point.x},${point.y},${point.normalizedX},${point.normalizedY},${point.timestamp}',
      );
    }

    return buffer.toString();
  }

  Map<String, dynamic> exportResultMetrics(TestResult result) {
    return {
      'test_type': result.testType.toString(),
      'timestamp': result.timestamp.toIso8601String(),
      'overall_score': result.overallScore,
      'result_category': result.resultCategory,
      'metrics': {
        'frequency_hz': result.metrics.frequency,
        'amplitude': result.metrics.amplitude,
        'deviation_from_baseline': result.metrics.deviationFromBaseline,
        'test_duration_seconds': result.metrics.testDuration,
        'average_speed': result.metrics.averageSpeed,
        'mean': result.metrics.mean,
        'std': result.metrics.std,
      },
    };
  }
}

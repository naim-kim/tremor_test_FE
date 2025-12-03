import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import '../models/test_result.dart';
import '../utils/fft_analyzer.dart';
import '../utils/spiral_generator.dart';
import '../utils/spiral_analyzer.dart';

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
    if (testType == TestType.spiral) {
      // Use SpiralAnalyzer for spiral tests (matching data engineer's code)
      return await _analyzeSpiralTest(points);
    } else {
      // Use existing FFT analyzer for pentagon tests
      return await _analyzePentagonTest(points);
    }
  }

  /// Analyze spiral test using SpiralAnalyzer (matching data engineer's code)
  Future<TestResult> _analyzeSpiralTest(List<DrawingPoint> points) async {
    if (points.isEmpty) {
      throw ArgumentError('Points list cannot be empty');
    }

    // Get baseline reference points
    final canvasSize = 300.0;
    final baselinePoints = SpiralGenerator.getSpiralPoints(canvasSize, 500);

    final refPoints = baselinePoints;

    // Create SpiralAnalyzer and run analysis
    final analyzer = const SpiralAnalyzer();
    final spiralResult = analyzer.analyze(
      refPoints: refPoints,
      drawingPoints: points,
    );

    // Create TremorMetrics from spiral analysis result
    final metrics = TremorMetrics(
      frequency: spiralResult.dominantTremorFreq,
      amplitude: spiralResult.tremorAmplitude,
      deviationFromBaseline: spiralResult.meanError,
      testDuration: spiralResult.totalTime,
      averageSpeed: spiralResult.avgSpeed,
      mean: spiralResult.meanError,
      std: _calculateStd(spiralResult.distanceErrors),
    );

    // Use judgment message as result category (focus on message, not score)
    final resultCategory = spiralResult.judgment;

    // Calculate a simple score for display (but focus on message)
    final overallScore = _calculateSpiralScore(spiralResult);

    return TestResult(
      id: _uuid.v4(),
      userId: 'current_user', // Replace with actual user ID
      testType: TestType.spiral,
      timestamp: DateTime.now(),
      drawingPoints: points,
      overallScore: overallScore,
      metrics: metrics,
      resultCategory: resultCategory,
    );
  }

  /// Analyze pentagon test using existing FFT analyzer
  Future<TestResult> _analyzePentagonTest(List<DrawingPoint> points) async {
    // Perform FFT analysis
    final metrics = await FFTAnalyzer.analyze(points);

    // Update metrics
    final updatedMetrics = TremorMetrics(
      frequency: metrics.frequency,
      amplitude: metrics.amplitude,
      deviationFromBaseline: 0, // Not applicable for pentagon
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
      testType: TestType.pentagon,
      timestamp: DateTime.now(),
      drawingPoints: points,
      overallScore: overallScore,
      metrics: updatedMetrics,
      resultCategory: resultCategory,
    );
  }

  /// Calculate score for spiral test (simplified, focus on message)
  double _calculateSpiralScore(SpiralAnalysisResult result) {
    // Scoring based on relative mean error so that scores are
    // more device- and scale-independent.
    // relativeMeanError is meanError normalized by spiral radius (0~1+).
    final rel = result.relativeMeanError;

    if (rel <= 0.05) {
      return 85.0; // Good: <= 5% of spiral radius
    } else if (rel <= 0.08) {
      return 70.0; // Fair
    } else if (rel <= 0.12) {
      return 55.0; // Average
    } else if (rel <= 0.18) {
      return 40.0; // Needs attention
    } else {
      return 25.0; // Poor
    }
  }

  double _calculateStd(List<double> values) {
    if (values.isEmpty) {
      return 0.0;
    }
    final double mean = values.reduce((a, b) => a + b) / values.length;
    final double variance = values.fold<double>(
          0.0,
          (sum, value) => sum + math.pow(value - mean, 2).toDouble(),
        ) /
        values.length;
    return math.sqrt(variance);
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

    // Automatically save CSV file
    try {
      await _saveResultToCSV(result);
    } catch (e) {
      // Silently fail CSV export - don't block result saving
      debugPrint('Failed to save CSV: $e');
    }

    notifyListeners();
  }

  /// Save test result to CSV file automatically
  Future<void> _saveResultToCSV(TestResult result) async {
    try {
      Directory testDataDir;

      // Platform-specific path handling
      if (kIsWeb) {
        // For web, we can't save to file system directly
        // This will need special handling (download trigger)
        // For now, skip file saving on web
        debugPrint('CSV saving skipped on web platform');
        return;
      } else if (Platform.isWindows) {
        // Use hardcoded path for Windows
        const hardcodedPath = r'C:\Users\User\GitHub\BCI_Lab\tremor_test_data';
        testDataDir = Directory(hardcodedPath);
      } else {
        // For mobile platforms (Android/iOS), use application documents directory
        final directory = await getApplicationDocumentsDirectory();
        testDataDir = Directory(path.join(directory.path, 'tremor_test_data'));
      }

      // Create directory if it doesn't exist
      if (!await testDataDir.exists()) {
        await testDataDir.create(recursive: true);
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(result.timestamp);
      final testTypeStr =
          result.testType == TestType.spiral ? 'spiral' : 'pentagon';
      final filename =
          '${testTypeStr}_${timestamp}_${result.id.substring(0, 8)}.csv';
      final filePath = path.join(testDataDir.path, filename);
      final file = File(filePath);

      // Generate CSV content
      final csvContent = _generateCSVContent(result);

      // Write to file
      await file.writeAsString(csvContent);

      debugPrint('CSV saved to: $filePath');
    } catch (e) {
      debugPrint('Error saving CSV: $e');
      rethrow;
    }
  }

  /// Get the path where CSV files are saved (for user reference)
  Future<String> getCSVSavePath() async {
    try {
      if (kIsWeb) {
        return 'Web platform - files are downloaded';
      } else if (Platform.isWindows) {
        // Use hardcoded path for Windows
        const hardcodedPath = r'C:\Users\User\GitHub\BCI_Lab\tremor_test_data';
        return hardcodedPath;
      } else {
        // For mobile platforms (Android/iOS), use application documents directory
        final directory = await getApplicationDocumentsDirectory();
        final testDataDir =
            Directory(path.join(directory.path, 'tremor_test_data'));
        return testDataDir.path;
      }
    } catch (e) {
      return 'Unable to determine path: $e';
    }
  }

  /// Generate comprehensive CSV content with both drawing points and metrics
  String _generateCSVContent(TestResult result) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    // Header section with metadata
    buffer.writeln('# Tremor Test Data Export');
    buffer.writeln('# Test ID: ${result.id}');
    buffer.writeln('# Test Type: ${result.testType}');
    buffer.writeln('# Timestamp: ${dateFormat.format(result.timestamp)}');
    buffer.writeln('# User ID: ${result.userId}');
    buffer
        .writeln('# Overall Score: ${result.overallScore.toStringAsFixed(2)}');
    buffer.writeln('# Result Category: ${result.resultCategory}');
    buffer.writeln('');

    // Metrics section
    buffer.writeln('# Metrics');
    buffer.writeln('Metric,Value,Unit');
    buffer
        .writeln('Frequency,${result.metrics.frequency.toStringAsFixed(4)},Hz');
    buffer
        .writeln('Amplitude,${result.metrics.amplitude.toStringAsFixed(4)},px');
    buffer.writeln(
        'Deviation from Baseline,${result.metrics.deviationFromBaseline.toStringAsFixed(4)},px');
    buffer.writeln(
        'Test Duration,${result.metrics.testDuration.toStringAsFixed(4)},seconds');
    buffer.writeln(
        'Average Speed,${result.metrics.averageSpeed.toStringAsFixed(4)},px/s');
    buffer.writeln('Mean,${result.metrics.mean.toStringAsFixed(4)},px');
    buffer.writeln(
        'Standard Deviation,${result.metrics.std.toStringAsFixed(4)},px');

    // For spiral tests, append algorithm-specific summary metrics.
    if (result.testType == TestType.spiral) {
      // These are currently derived from the spiral analyzer and can be
      // extended to include relative metrics if needed in the future.
      buffer.writeln(
          'Spiral_Mean_Error,${result.metrics.deviationFromBaseline.toStringAsFixed(4)},px');
    }

    buffer.writeln('');

    // Baseline points section (for spiral tests)
    if (result.testType == TestType.spiral) {
      buffer.writeln('# Baseline Reference Points (Spiral)');
      buffer.writeln(
          '# Generated using: r = t, theta = t, t from 0 to 6*PI (3 turns)');
      buffer.writeln('# Formula: x = t * cos(t), y = t * sin(t)');
      buffer.writeln('baseline_x,baseline_y');

      // Get baseline points (same as used in analysis)
      const canvasSize = 300.0;
      const numBaselinePoints = 500;
      final baselinePoints =
          SpiralGenerator.getSpiralPoints(canvasSize, numBaselinePoints);

      for (final point in baselinePoints) {
        buffer.writeln(
          '${point.dx.toStringAsFixed(4)},'
          '${point.dy.toStringAsFixed(4)}',
        );
      }
      buffer.writeln('');
    }

    // User drawing points section
    buffer.writeln('# User Drawing Points');
    buffer.writeln('x,y,normalizedX,normalizedY,timestamp_ms');

    // Data points
    for (final point in result.drawingPoints) {
      buffer.writeln(
        '${point.x.toStringAsFixed(4)},'
        '${point.y.toStringAsFixed(4)},'
        '${point.normalizedX.toStringAsFixed(6)},'
        '${point.normalizedY.toStringAsFixed(6)},'
        '${point.timestamp}',
      );
    }

    return buffer.toString();
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

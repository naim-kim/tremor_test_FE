import 'package:hive/hive.dart';
import 'dart:math' as math;

part 'test_result.g.dart';

@HiveType(typeId: 0)
class TestResult extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final TestType testType;

  @HiveField(3)
  final DateTime timestamp;

  @HiveField(4)
  final List<DrawingPoint> drawingPoints;

  @HiveField(5)
  final double overallScore;

  @HiveField(6)
  final TremorMetrics metrics;

  @HiveField(7)
  final String resultCategory; // "매우 좋음", "좋음", "보통", "주의 필요", "병원 방문 권장"

  TestResult({
    required this.id,
    required this.userId,
    required this.testType,
    required this.timestamp,
    required this.drawingPoints,
    required this.overallScore,
    required this.metrics,
    required this.resultCategory,
  });
}

@HiveType(typeId: 1)
enum TestType {
  @HiveField(0)
  spiral,

  @HiveField(1)
  pentagon,
}

@HiveType(typeId: 2)
class DrawingPoint extends HiveObject {
  @HiveField(0)
  final double x; // Absolute pixel position

  @HiveField(1)
  final double y; // Absolute pixel position

  @HiveField(2)
  final double normalizedX; // 0-1 normalized

  @HiveField(3)
  final double normalizedY; // 0-1 normalized

  @HiveField(4)
  final int timestamp; // milliseconds from start

  DrawingPoint({
    required this.x,
    required this.y,
    required this.normalizedX,
    required this.normalizedY,
    required this.timestamp,
  });
}

@HiveType(typeId: 3)
class TremorMetrics extends HiveObject {
  @HiveField(0)
  final double frequency; // 떨림의 주파수 (Hz)

  @HiveField(1)
  final double amplitude; // 떨림의 세기

  @HiveField(2)
  final double deviationFromBaseline; // 목표선에서 벗어난 거리

  @HiveField(3)
  final double testDuration; // 검사 수행 시간 (seconds)

  @HiveField(4)
  final double averageSpeed; // 검사 평균 속도

  @HiveField(5)
  final double mean; // FFT mean

  @HiveField(6)
  final double std; // FFT standard deviation

  TremorMetrics({
    required this.frequency,
    required this.amplitude,
    required this.deviationFromBaseline,
    required this.testDuration,
    required this.averageSpeed,
    required this.mean,
    required this.std,
  });
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/test_result.dart';
import '../widgets/drawing_comparison.dart';
import '../widgets/metrics_card.dart';

class ResultScreen extends StatelessWidget {
  final TestResult result;

  const ResultScreen({super.key, required this.result});

  // Design Constants
  static const _gradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const _primaryColor = Color(0xFF667eea);

  @override
  Widget build(BuildContext context) {
    final userName = result.userId;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '검사 결과',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('yyyy년 MM월 dd일 HH:mm').format(result.timestamp),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '종합 점수',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Overall Score with Segmented Circular Progress
                  _SegmentedCircularScoreCard(result: result),
                  const SizedBox(height: 20),

                  const Text(
                    '점수 분포',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ResultCategoryCard(result: result, userName: userName),
                  const SizedBox(height: 20),

                  const Text(
                    '그림 비교',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DrawingComparison(result: result),
                  const SizedBox(height: 20),

                  const Text(
                    '세부항목 수치 계산',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MetricsCard(metrics: result.metrics),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('공유 기능 준비 중입니다'),
                                    backgroundColor: Colors.black87,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share_rounded,
                                        color: _primaryColor, size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '결과 공유',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: _primaryColor,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white,
                                Colors.white.withOpacity(0.95)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            icon: Icon(Icons.home_rounded,
                                color: _primaryColor, size: 20),
                            label: const Text(
                              '홈으로',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 세그먼트 원형 점수 카드 (각 항목별 비율 표시)
class _SegmentedCircularScoreCard extends StatelessWidget {
  final TestResult result;

  const _SegmentedCircularScoreCard({required this.result});

  // 각 항목별 점수 계산 (0-100 기준)
  Map<String, double> _calculateSegmentScores() {
    final metrics = result.metrics;

    // 주파수 점수 (3-12Hz 범위 체크, 20점 만점)
    double frequencyScore = 20.0;
    if (metrics.frequency >= 3 && metrics.frequency <= 12) {
      frequencyScore = 20.0 - (metrics.frequency / 12) * 20;
    }

    // 진폭 점수 (25점 만점)
    double amplitudeScore = math.max(0, 25.0 - (metrics.amplitude / 10) * 25);

    // 편차 점수 (25점 만점)
    double deviationScore = 25.0;
    if (metrics.deviationFromBaseline > 0) {
      deviationScore =
          math.max(0, 25.0 - (metrics.deviationFromBaseline / 50) * 25);
    }

    // 시간 점수 (15점 만점)
    double durationScore = 15.0;
    if (metrics.testDuration < 10) {
      durationScore =
          math.max(0, 15.0 - ((10 - metrics.testDuration) / 10) * 15);
    } else if (metrics.testDuration > 30) {
      durationScore =
          math.max(0, 15.0 - ((metrics.testDuration - 30) / 30) * 15);
    }

    // 속도 점수 (15점 만점)
    double speedScore = 15.0;
    final normalizedSpeed = (metrics.averageSpeed / 100).clamp(0.0, 1.0);
    if (normalizedSpeed > 0.8 || normalizedSpeed < 0.2) {
      speedScore = 0;
    }

    return {
      '주파수': frequencyScore,
      '진폭': amplitudeScore,
      '정확도': deviationScore,
      '시간': durationScore,
      '속도': speedScore,
    };
  }

  @override
  Widget build(BuildContext context) {
    final segmentScores = _calculateSegmentScores();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 세그먼트 원형 그래프
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CustomPaint(
                            painter: _SegmentedCircularProgressPainter(
                              segments: segmentScores,
                              totalScore: result.overallScore,
                            ),
                          ),
                        ),
                        const Spacer(),

                        // 범례
                        SizedBox(
                          child: _ScoreLegend(segments: segmentScores),
                        ),
                        const SizedBox(width: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              result.resultCategory,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 범례
class _ScoreLegend extends StatelessWidget {
  final Map<String, double> segments;

  const _ScoreLegend({required this.segments});

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFFF6B6B), // 주파수 - 빨강
      const Color(0xFFFFD93D), // 진폭 - 노랑
      const Color(0xFF6BCF7F), // 정확도 - 초록
      const Color(0xFF4ECDC4), // 시간 - 청록
      const Color(0xFF95E1D3), // 속도 - 민트
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final entries = segments.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final percentage = (entry.value / 100 * 100).toStringAsFixed(0);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _getColorForIndex(index),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key} $percentage%',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// 세그먼트 원형 프로그레스 페인터
class _SegmentedCircularProgressPainter extends CustomPainter {
  final Map<String, double> segments;
  final double totalScore;

  _SegmentedCircularProgressPainter({
    required this.segments,
    required this.totalScore,
  });

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFD93D),
      const Color(0xFF6BCF7F),
      const Color(0xFF4ECDC4),
      const Color(0xFF95E1D3),
    ];
    return colors[index % colors.length];
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 15;

    // 배경 원
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.butt;

    canvas.drawCircle(center, radius, bgPaint);

    // 각 세그먼트 그리기
    double startAngle = -math.pi / 2;
    final entries = segments.entries.toList();

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final percentage = entry.value / 100;
      final sweepAngle = 2 * math.pi * percentage;

      final segmentPaint = Paint()
        ..color = _getColorForIndex(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        segmentPaint,
      );

      startAngle += sweepAngle;
    }

    // 중앙 텍스트 (총점 퍼센트)
    final percentage = (totalScore).toStringAsFixed(0);
    final textPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: percentage,
            style: const TextStyle(
              color: Color(0xFF667eea),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: '점',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_SegmentedCircularProgressPainter oldDelegate) {
    return true;
  }
}

// 결과 카테고리 카드 (직선 차트 + 코멘트)
class _ResultCategoryCard extends StatelessWidget {
  final TestResult result;
  final String userName;

  const _ResultCategoryCard({
    required this.result,
    required this.userName,
  });

  Color _getCategoryColor(String category) {
    switch (category) {
      case '매우 좋음':
        return Colors.green;
      case '좋음':
        return Colors.lightGreen;
      case '보통':
        return Colors.orange;
      case '주의 필요':
        return Colors.deepOrange;
      case '병원 방문 권장':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(result.resultCategory);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StraightLineChart(score: result.overallScore),
        ],
      ),
    );
  }
}

// 직선 차트
class _StraightLineChart extends StatelessWidget {
  final double score;

  const _StraightLineChart({required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: CustomPaint(
            painter: _StraightLineChartPainter(score: score),
            child: const SizedBox(width: double.infinity),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ChartLabel(
              text: '병원 방문 권장',
              color: Colors.red,
              isActive: score < 40,
            ),
            _ChartLabel(
              text: '주의 필요',
              color: Colors.deepOrange,
              isActive: score >= 40 && score < 55,
            ),
            _ChartLabel(
              text: '보통',
              color: Colors.orange,
              isActive: score >= 55 && score < 70,
            ),
            _ChartLabel(
              text: '좋음',
              color: Colors.lightGreen,
              isActive: score >= 70 && score < 85,
            ),
            _ChartLabel(
              text: '매우 좋음',
              color: Colors.green,
              isActive: score >= 85,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChartLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool isActive;

  const _ChartLabel({
    required this.text,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey[500],
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            height: 1.3,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// 직선 차트 페인터
class _StraightLineChartPainter extends CustomPainter {
  final double score;

  _StraightLineChartPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final sections = [
      {'color': Colors.red, 'start': 0.0, 'end': 0.4},
      {'color': Colors.deepOrange, 'start': 0.4, 'end': 0.55},
      {'color': Colors.orange, 'start': 0.55, 'end': 0.7},
      {'color': Colors.lightGreen, 'start': 0.7, 'end': 0.85},
      {'color': Colors.green, 'start': 0.85, 'end': 1.0},
    ];

    final y = size.height / 2;

    // 배경 선 (회색)
    for (final section in sections) {
      paint.color = (section['color'] as Color).withOpacity(0.2);
      final startX = (section['start'] as double) * size.width;
      final endX = (section['end'] as double) * size.width;
      canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
    }

    // 점수까지 활성화된 선
    final scoreRatio = (score / 100).clamp(0.0, 1.0);
    for (final section in sections) {
      final start = section['start'] as double;
      final end = section['end'] as double;

      if (scoreRatio > start) {
        paint.color = section['color'] as Color;
        final startX = start * size.width;
        final endX = math.min(scoreRatio, end) * size.width;
        canvas.drawLine(Offset(startX, y), Offset(endX, y), paint);
      }
    }

    // 사용자 점수 마커
    final scoreX = scoreRatio * size.width;

    // 외곽 원 (흰색)
    canvas.drawCircle(
      Offset(scoreX, y),
      16,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 내부 원 (그라데이션)
    canvas.drawCircle(
      Offset(scoreX, y),
      12,
      Paint()
        ..color = const Color(0xFF667eea)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_StraightLineChartPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

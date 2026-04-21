import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../models/test_result.dart';
import '../widgets/drawing_comparison.dart';
import '../widgets/metrics_card.dart';
import '../theme/app_colors.dart';

String _compactCategory(String value) {
  final head = value.split(':').first.trim();
  return head.isEmpty ? value : head;
}

class ResultScreen extends StatelessWidget {
  final TestResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Column(
          children: [
            // ── App bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withOpacity(0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '검사 결과',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A18),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 12),
                      child: Text(
                        DateFormat('yyyy년 MM월 dd일 HH:mm')
                            .format(result.timestamp),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),

                    // ── Score card ───────────────────────────────────
                    _ScoreCard(result: result),

                    const SizedBox(height: 10),

                    // ── Score bar ────────────────────────────────────
                    _ScoreBarCard(score: result.overallScore),

                    const SizedBox(height: 10),

                    // ── Drawing comparison ───────────────────────────
                    _SectionLabel(label: '그림 비교'),
                    const SizedBox(height: 8),
                    _WhiteCard(child: DrawingComparison(result: result)),

                    const SizedBox(height: 10),

                    // ── Metrics ──────────────────────────────────────
                    _SectionLabel(label: '세부 수치'),
                    const SizedBox(height: 8),
                    _WhiteCard(child: MetricsCard(metrics: result.metrics)),

                    const SizedBox(height: 20),

                    // ── Actions ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('공유 기능 준비 중입니다')),
                                );
                              },
                              icon: const Icon(Icons.share_rounded, size: 16),
                              label: const Text('공유'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1A1A18),
                                side: BorderSide(
                                    color: Colors.black.withOpacity(0.12),
                                    width: 0.5),
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.of(context)
                                  .popUntil((r) => r.isFirst),
                              icon: const Icon(Icons.home_rounded, size: 16),
                              label: const Text('홈으로'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal800,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A18),
        letterSpacing: -0.1,
      ),
    );
  }
}

class _WhiteCard extends StatelessWidget {
  final Widget child;
  const _WhiteCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: child,
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final TestResult result;
  const _ScoreCard({required this.result});

  Map<String, double> get _segments {
    final m = result.metrics;
    double freq = 20.0;
    if (m.frequency >= 3 && m.frequency <= 12) {
      freq = 20.0 - (m.frequency / 12) * 20;
    }
    final amp = math.max(0.0, 25.0 - (m.amplitude / 10) * 25);
    final dev = m.deviationFromBaseline > 0
        ? math.max(0.0, 25.0 - (m.deviationFromBaseline / 50) * 25)
        : 25.0;
    double dur = 15.0;
    if (m.testDuration < 10) {
      dur = math.max(0.0, 15.0 - ((10 - m.testDuration) / 10) * 15);
    } else if (m.testDuration > 30) {
      dur = math.max(0.0, 15.0 - ((m.testDuration - 30) / 30) * 15);
    }
    final spd = ((m.averageSpeed / 100).clamp(0.0, 1.0) > 0.8 ||
            (m.averageSpeed / 100).clamp(0.0, 1.0) < 0.2)
        ? 0.0
        : 15.0;
    return {'주파수': freq, '진폭': amp, '정확도': dev, '시간': dur, '속도': spd};
  }

  static const _colors = [
    AppColors.teal800,
    AppColors.teal600,
    AppColors.teal400,
    AppColors.amber600,
    AppColors.amber400,
  ];

  @override
  Widget build(BuildContext context) {
    final segs = _segments;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          // Donut chart
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _DonutPainter(
                segments: segs,
                totalScore: result.overallScore,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F5EE),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    _compactCategory(result.resultCategory),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 10),
                ...segs.entries.toList().asMap().entries.map((e) {
                  final idx = e.key;
                  final entry = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _colors[idx % _colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry.key,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.value.toStringAsFixed(0)}점',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _colors[idx % _colors.length],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, double> segments;
  final double totalScore;

  static const _colors = [
    AppColors.teal800,
    AppColors.teal600,
    AppColors.teal400,
    AppColors.amber600,
    AppColors.amber400,
  ];

  const _DonutPainter({required this.segments, required this.totalScore});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 8;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey.shade100
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    double startAngle = -math.pi / 2;
    final entries = segments.entries.toList();
    for (int i = 0; i < entries.length; i++) {
      final sweep = 2 * math.pi * (entries[i].value / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = _colors[i % _colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }

    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '${totalScore.toStringAsFixed(0)}',
            style: const TextStyle(
              color: AppColors.teal800,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          TextSpan(
            text: '점',
            style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DonutPainter old) => false;
}

// ── Score bar card ────────────────────────────────────────────────────────────

class _ScoreBarCard extends StatelessWidget {
  final double score;
  const _ScoreBarCard({required this.score});

  static const _bands = [
    {'label': '병원 권장', 'color': AppColors.error600, 'from': 0.0, 'to': 0.4},
    {'label': '주의', 'color': AppColors.amber600, 'from': 0.4, 'to': 0.55},
    {'label': '보통', 'color': AppColors.amber400, 'from': 0.55, 'to': 0.7},
    {'label': '좋음', 'color': AppColors.teal400, 'from': 0.7, 'to': 0.85},
    {'label': '매우 좋음', 'color': AppColors.teal800, 'from': 0.85, 'to': 1.0},
  ];

  @override
  Widget build(BuildContext context) {
    final ratio = (score / 100).clamp(0.0, 1.0);
    final activeIdx = _bands.indexWhere(
      (b) => ratio >= (b['from'] as double) && ratio < (b['to'] as double),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: _bands.map((b) {
                      final bandW =
                          ((b['to'] as double) - (b['from'] as double)) * w;
                      return Container(
                        width: bandW,
                        height: 10,
                        color: (b['color'] as Color).withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: _bands.asMap().entries.map((e) {
                      final b = e.value;
                      final from = b['from'] as double;
                      final to = b['to'] as double;
                      final color = b['color'] as Color;
                      final bandW = (to - from) * w;
                      if (ratio <= from) {
                        return SizedBox(width: bandW, height: 10);
                      } else if (ratio >= to) {
                        return Container(
                            width: bandW, height: 10, color: color);
                      } else {
                        final fillW = (ratio - from) / (to - from) * bandW;
                        return Row(children: [
                          Container(width: fillW, height: 10, color: color),
                          SizedBox(width: bandW - fillW, height: 10),
                        ]);
                      }
                    }).toList(),
                  ),
                ),
                Positioned(
                  left: ratio * w - 8,
                  top: -4,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.teal800, width: 2.5),
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 12),
          Row(
            children: _bands.asMap().entries.map((e) {
              final idx = e.key;
              final b = e.value;
              final isActive = idx == activeIdx;
              return Expanded(
                child: Text(
                  b['label'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: isActive ? b['color'] as Color : Colors.grey[400],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

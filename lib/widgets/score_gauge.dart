import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScoreGauge extends StatelessWidget {
  final double score; // 0-100

  const ScoreGauge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: CustomPaint(
            painter: _GaugePainter(score: score),
            child: const SizedBox(width: double.infinity),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _GaugeLabel(
              text: '병원 방문\n권장',
              color: Colors.red,
              isActive: score < 40,
            ),
            _GaugeLabel(
              text: '주의\n필요',
              color: Colors.deepOrange,
              isActive: score >= 40 && score < 55,
            ),
            _GaugeLabel(
              text: '보통',
              color: Colors.orange,
              isActive: score >= 55 && score < 70,
            ),
            _GaugeLabel(
              text: '좋음',
              color: Colors.lightGreen,
              isActive: score >= 70 && score < 85,
            ),
            _GaugeLabel(
              text: '매우\n좋음',
              color: Colors.green,
              isActive: score >= 85,
            ),
          ],
        ),
      ],
    );
  }
}

class _GaugeLabel extends StatelessWidget {
  final String text;
  final Color color;
  final bool isActive;

  const _GaugeLabel({
    required this.text,
    required this.color,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? color : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? color : Colors.grey[400],
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;

  _GaugePainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 2);
    const startAngle = math.pi;
    const sweepAngle = math.pi;

    // Draw background arc segments with different colors
    final segments = [
      {'color': Colors.red, 'start': 0.0, 'end': 0.4},
      {'color': Colors.deepOrange, 'start': 0.4, 'end': 0.55},
      {'color': Colors.orange, 'start': 0.55, 'end': 0.7},
      {'color': Colors.lightGreen, 'start': 0.7, 'end': 0.85},
      {'color': Colors.green, 'start': 0.85, 'end': 1.0},
    ];

    for (final segment in segments) {
      paint.color = (segment['color'] as Color).withOpacity(0.2);
      canvas.drawArc(
        rect,
        startAngle + sweepAngle * (segment['start'] as double),
        sweepAngle *
            ((segment['end'] as double) - (segment['start'] as double)),
        false,
        paint,
      );
    }

    // Draw score indicator
    final scoreRatio = (score / 100).clamp(0.0, 1.0);
    final scoreAngle = startAngle + sweepAngle * scoreRatio;

    // Determine color based on score
    Color indicatorColor;
    if (score < 40) {
      indicatorColor = Colors.red;
    } else if (score < 55) {
      indicatorColor = Colors.deepOrange;
    } else if (score < 70) {
      indicatorColor = Colors.orange;
    } else if (score < 85) {
      indicatorColor = Colors.lightGreen;
    } else {
      indicatorColor = Colors.green;
    }

    // Draw active arc
    paint.color = indicatorColor;
    paint.strokeWidth = 12;
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * scoreRatio,
      false,
      paint,
    );

    // Draw indicator dot
    final indicatorX = rect.center.dx + (rect.width / 2) * math.cos(scoreAngle);
    final indicatorY =
        rect.center.dy + (rect.height / 2) * math.sin(scoreAngle);

    final dotPaint = Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, dotPaint);

    // Draw white border on dot
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(indicatorX, indicatorY), 8, borderPaint);
  }

  @override
  bool shouldRepaint(_GaugePainter oldDelegate) {
    return oldDelegate.score != score;
  }
}

import 'package:flutter/material.dart';
import '../models/test_result.dart';
import '../utils/spiral_generator.dart';

class DrawingComparison extends StatelessWidget {
  final TestResult result;

  const DrawingComparison({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: _ComparisonPainter(
            result: result,
            showBaseline: result.testType == TestType.spiral,
          ),
          size: const Size(300, 300),
        ),
      ),
    );
  }
}

class _ComparisonPainter extends CustomPainter {
  final TestResult result;
  final bool showBaseline;

  _ComparisonPainter({
    required this.result,
    required this.showBaseline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factor to fit drawing in canvas
    final points = result.drawingPoints;
    if (points.isEmpty) return;

    // Find bounds of user drawing
    double minX = points.first.x;
    double maxX = points.first.x;
    double minY = points.first.y;
    double maxY = points.first.y;

    for (final point in points) {
      if (point.x < minX) minX = point.x;
      if (point.x > maxX) maxX = point.x;
      if (point.y < minY) minY = point.y;
      if (point.y > maxY) maxY = point.y;
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = rangeX > rangeY ? rangeX : rangeY;

    if (maxRange == 0) return;

    final padding = 30.0;
    final scale = (size.width - 2 * padding) / maxRange;
    final offsetX = minX + rangeX / 2;
    final offsetY = minY + rangeY / 2;

    // Draw baseline (spiral) if applicable
    if (showBaseline) {
      final baselinePath = SpiralGenerator.generateSpiralPath(size.width);
      final baselinePaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(baselinePath, baselinePaint);
    }

    // Draw user's drawing
    final userPaint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Scale and center the first point
    final firstScaledX = size.width / 2 + (points.first.x - offsetX) * scale;
    final firstScaledY = size.height / 2 + (points.first.y - offsetY) * scale;
    path.moveTo(firstScaledX, firstScaledY);

    for (int i = 1; i < points.length; i++) {
      final scaledX = size.width / 2 + (points[i].x - offsetX) * scale;
      final scaledY = size.height / 2 + (points[i].y - offsetY) * scale;
      path.lineTo(scaledX, scaledY);
    }

    canvas.drawPath(path, userPaint);

    // Draw start point indicator
    final startPaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(firstScaledX, firstScaledY), 6, startPaint);

    // Draw end point indicator
    final endScaledX = size.width / 2 + (points.last.x - offsetX) * scale;
    final endScaledY = size.height / 2 + (points.last.y - offsetY) * scale;
    final endPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(endScaledX, endScaledY), 6, endPaint);
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}

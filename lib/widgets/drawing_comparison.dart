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

    // Draw user's drawing - 선을 끊어서 그리기
    final userPaint = Paint()
      ..color = const Color(0xFF4A90E2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 연속된 점들을 그룹화하여 그리기
    List<List<DrawingPoint>> segments = [];
    List<DrawingPoint> currentSegment = [];

    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      if (i == 0) {
        // 첫 점
        currentSegment.add(point);
      } else {
        final prevPoint = points[i - 1];
        final timeDiff = point.timestamp - prevPoint.timestamp;

        // 시간 차이가 50ms 이상이면 선이 끊긴 것으로 판단
        if (timeDiff > 50) {
          // 이전 세그먼트 저장
          if (currentSegment.isNotEmpty) {
            segments.add(List.from(currentSegment));
          }
          // 새 세그먼트 시작
          currentSegment = [point];
        } else {
          currentSegment.add(point);
        }
      }
    }

    // 마지막 세그먼트 추가
    if (currentSegment.isNotEmpty) {
      segments.add(currentSegment);
    }

    // 각 세그먼트별로 그리기
    for (final segment in segments) {
      if (segment.isEmpty) continue;

      final path = Path();

      // 세그먼트의 첫 점으로 이동
      final firstPoint = segment.first;
      final firstScaledX = size.width / 2 + (firstPoint.x - offsetX) * scale;
      final firstScaledY = size.height / 2 + (firstPoint.y - offsetY) * scale;
      path.moveTo(firstScaledX, firstScaledY);

      // 세그먼트의 나머지 점들 연결
      for (int i = 1; i < segment.length; i++) {
        final scaledX = size.width / 2 + (segment[i].x - offsetX) * scale;
        final scaledY = size.height / 2 + (segment[i].y - offsetY) * scale;
        path.lineTo(scaledX, scaledY);
      }

      canvas.drawPath(path, userPaint);
    }

    // Draw start and end point indicators for the first segment
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      final firstSegment = segments.first;

      // Start point (green)
      final startPoint = firstSegment.first;
      final startScaledX = size.width / 2 + (startPoint.x - offsetX) * scale;
      final startScaledY = size.height / 2 + (startPoint.y - offsetY) * scale;

      final startPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startScaledX, startScaledY), 6, startPaint);

      // End point (red) - 마지막 세그먼트의 마지막 점
      final lastSegment = segments.last;
      final endPoint = lastSegment.last;
      final endScaledX = size.width / 2 + (endPoint.x - offsetX) * scale;
      final endScaledY = size.height / 2 + (endPoint.y - offsetY) * scale;

      final endPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endScaledX, endScaledY), 6, endPaint);
    }
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}

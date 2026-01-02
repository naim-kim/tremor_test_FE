import 'package:flutter/material.dart';
import '../models/test_result.dart';
import '../utils/spiral_generator.dart';

class DrawingComparison extends StatelessWidget {
  final TestResult result;

  const DrawingComparison({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Pentagon uses 500x300, Spiral uses 300x300
    final bool isPentagon = result.testType == TestType.pentagon;
    final double originalWidth = isPentagon ? 500.0 : 300.0;
    final double originalHeight = 300.0;
    final double aspectRatio = originalWidth / originalHeight;

    return Container(
      width: double.infinity,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: CustomPaint(
                  painter: _ComparisonPainter(
                    result: result,
                    showBaseline: result.testType == TestType.spiral,
                    originalWidth: originalWidth,
                    originalHeight: originalHeight,
                    displayWidth: constraints.maxWidth,
                    displayHeight: constraints.maxHeight,
                  ),
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ComparisonPainter extends CustomPainter {
  final TestResult result;
  final bool showBaseline;
  final double originalWidth;
  final double originalHeight;
  final double displayWidth;
  final double displayHeight;

  _ComparisonPainter({
    required this.result,
    required this.showBaseline,
    required this.originalWidth,
    required this.originalHeight,
    required this.displayWidth,
    required this.displayHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final points = result.drawingPoints;
    if (points.isEmpty) return;

    // Calculate scale factors
    final scaleX = displayWidth / originalWidth;
    final scaleY = displayHeight / originalHeight;

    // Draw baseline (spiral) if applicable
    if (showBaseline) {
      final baselinePath = SpiralGenerator.generateSpiralPath(originalWidth);
      final scaledPath = _scalePath(baselinePath, scaleX, scaleY);

      final baselinePaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(scaledPath, baselinePaint);
    }

    // Draw user's drawing with scaling
    final userPaint = Paint()
      ..color = const Color(0xFF667eea)
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
        currentSegment.add(point);
      } else {
        final prevPoint = points[i - 1];
        final timeDiff = point.timestamp - prevPoint.timestamp;

        // 시간 차이가 50ms 이상이면 선이 끊긴 것으로 판단
        if (timeDiff > 50) {
          if (currentSegment.isNotEmpty) {
            segments.add(List.from(currentSegment));
          }
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

    // 각 세그먼트별로 그리기 - 스케일 적용
    for (final segment in segments) {
      if (segment.isEmpty) continue;

      final path = Path();
      final firstPoint = segment.first;
      path.moveTo(firstPoint.x * scaleX, firstPoint.y * scaleY);

      for (int i = 1; i < segment.length; i++) {
        path.lineTo(segment[i].x * scaleX, segment[i].y * scaleY);
      }

      canvas.drawPath(path, userPaint);
    }

    // Draw start and end point indicators
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      final firstSegment = segments.first;

      // Start point (green)
      final startPoint = firstSegment.first;
      final startPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(startPoint.x * scaleX, startPoint.y * scaleY),
        6,
        startPaint,
      );

      // End point (red)
      final lastSegment = segments.last;
      final endPoint = lastSegment.last;
      final endPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(endPoint.x * scaleX, endPoint.y * scaleY),
        6,
        endPaint,
      );
    }
  }

  Path _scalePath(Path originalPath, double scaleX, double scaleY) {
    final scaledPath = Path();
    final metrics = originalPath.computeMetrics();

    for (final metric in metrics) {
      for (double distance = 0.0; distance < metric.length; distance += 1.0) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final point = tangent.position;
          if (distance == 0.0) {
            scaledPath.moveTo(point.dx * scaleX, point.dy * scaleY);
          } else {
            scaledPath.lineTo(point.dx * scaleX, point.dy * scaleY);
          }
        }
      }
    }

    return scaledPath;
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.result != result ||
        oldDelegate.displayWidth != displayWidth ||
        oldDelegate.displayHeight != displayHeight;
  }
}

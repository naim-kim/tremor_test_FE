import 'package:flutter/material.dart';
import '../models/test_result.dart';
import '../utils/spiral_generator.dart';
import '../theme/app_colors.dart';

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
    // Ensure nothing paints outside the card (prevents overflow artifacts).
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final points = result.drawingPoints;
    if (points.isEmpty) {
      canvas.restore();
      return;
    }

    // Compute bounds (pentagon drawings can exceed the nominal 500x300 area).
    // For spiral we keep the original coordinate space to match baseline.
    double minX = 0, minY = 0, maxX = originalWidth, maxY = originalHeight;
    if (result.testType == TestType.pentagon) {
      minX = points.first.x;
      maxX = points.first.x;
      minY = points.first.y;
      maxY = points.first.y;
      for (final p in points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
      // Add a little padding so strokes/markers don't touch edges.
      const pad = 12.0;
      minX -= pad;
      minY -= pad;
      maxX += pad;
      maxY += pad;
    }

    final contentW = (maxX - minX).clamp(1.0, double.infinity);
    final contentH = (maxY - minY).clamp(1.0, double.infinity);

    // Uniform scale to fit both width and height, then center.
    final scale = (displayWidth / contentW)
        .clamp(0.0, double.infinity)
        .isFinite
        ? (displayWidth / contentW)
        : 1.0;
    final scale2 = (displayHeight / contentH)
        .clamp(0.0, double.infinity)
        .isFinite
        ? (displayHeight / contentH)
        : 1.0;
    final s = scale < scale2 ? scale : scale2;

    final offsetX = (displayWidth - contentW * s) / 2 - minX * s;
    final offsetY = (displayHeight - contentH * s) / 2 - minY * s;

    // Draw baseline (spiral) if applicable
    if (showBaseline) {
      final baselinePath = SpiralGenerator.generateSpiralPath(originalWidth);
      final scaledPath = _scalePath(baselinePath, s, s, offsetX, offsetY);

      final baselinePaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(scaledPath, baselinePaint);
    }

    // Draw user's drawing with scaling
    final userPaint = Paint()
      ..color = AppColors.teal800
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
      path.moveTo(firstPoint.x * s + offsetX, firstPoint.y * s + offsetY);

      for (int i = 1; i < segment.length; i++) {
        path.lineTo(
          segment[i].x * s + offsetX,
          segment[i].y * s + offsetY,
        );
      }

      canvas.drawPath(path, userPaint);
    }

    // Draw start and end point indicators
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      final firstSegment = segments.first;

      // Start point (green)
      final startPoint = firstSegment.first;
      final startPaint = Paint()
        ..color = AppColors.amber600
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(startPoint.x * s + offsetX, startPoint.y * s + offsetY),
        6,
        startPaint,
      );

      // End point (red)
      final lastSegment = segments.last;
      final endPoint = lastSegment.last;
      final endPaint = Paint()
        ..color = AppColors.error600
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(endPoint.x * s + offsetX, endPoint.y * s + offsetY),
        6,
        endPaint,
      );
    }

    canvas.restore();
  }

  Path _scalePath(Path originalPath, double scaleX, double scaleY, double dx, double dy) {
    final scaledPath = Path();
    final metrics = originalPath.computeMetrics();

    for (final metric in metrics) {
      for (double distance = 0.0; distance < metric.length; distance += 1.0) {
        final tangent = metric.getTangentForOffset(distance);
        if (tangent != null) {
          final point = tangent.position;
          if (distance == 0.0) {
            scaledPath.moveTo(point.dx * scaleX + dx, point.dy * scaleY + dy);
          } else {
            scaledPath.lineTo(point.dx * scaleX + dx, point.dy * scaleY + dy);
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

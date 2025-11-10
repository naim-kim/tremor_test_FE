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

    // Draw baseline (spiral) if applicable - use same scale as test screen
    if (showBaseline) {
      final baselinePath = SpiralGenerator.generateSpiralPath(size.width);
      final baselinePaint = Paint()
        ..color = Colors.grey[300]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(baselinePath, baselinePaint);
    }

    // Draw user's drawing at original coordinates (no scaling)
    // Points are stored in absolute pixel coordinates (0-300 range from test screen)
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

    // 각 세그먼트별로 그리기 - 원본 좌표 사용 (스케일링 없음)
    for (final segment in segments) {
      if (segment.isEmpty) continue;

      final path = Path();

      // 세그먼트의 첫 점으로 이동 - 원본 좌표 그대로 사용
      final firstPoint = segment.first;
      path.moveTo(firstPoint.x, firstPoint.y);

      // 세그먼트의 나머지 점들 연결 - 원본 좌표 그대로 사용
      for (int i = 1; i < segment.length; i++) {
        path.lineTo(segment[i].x, segment[i].y);
      }

      canvas.drawPath(path, userPaint);
    }

    // Draw start and end point indicators for the first segment
    if (segments.isNotEmpty && segments.first.isNotEmpty) {
      final firstSegment = segments.first;

      // Start point (green) - 원본 좌표 사용
      final startPoint = firstSegment.first;
      final startPaint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(startPoint.x, startPoint.y), 6, startPaint);

      // End point (red) - 마지막 세그먼트의 마지막 점, 원본 좌표 사용
      final lastSegment = segments.last;
      final endPoint = lastSegment.last;
      final endPaint = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(endPoint.x, endPoint.y), 6, endPaint);
    }
  }

  @override
  bool shouldRepaint(_ComparisonPainter oldDelegate) {
    return oldDelegate.result != result;
  }
}

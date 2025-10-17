import 'package:flutter/material.dart';
import '../models/test_result.dart';

class DrawingCanvas extends StatelessWidget {
  final double size;
  final Path? baselinePath;
  final List<DrawingPoint?> userPoints; // null을 포함하도록 변경
  final Function(Offset) onPanStart;
  final Function(Offset) onPanUpdate;
  final Function() onPanEnd;
  final bool showBaseline;

  const DrawingCanvas({
    super.key,
    required this.size,
    this.baselinePath,
    required this.userPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    this.showBaseline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: GestureDetector(
          onPanStart: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition =
                renderBox.globalToLocal(details.globalPosition);
            if (_isWithinCanvas(localPosition)) {
              onPanStart(localPosition);
            }
          },
          onPanUpdate: (details) {
            final RenderBox renderBox = context.findRenderObject() as RenderBox;
            final localPosition =
                renderBox.globalToLocal(details.globalPosition);
            if (_isWithinCanvas(localPosition)) {
              onPanUpdate(localPosition);
            }
          },
          onPanEnd: (_) => onPanEnd(),
          child: CustomPaint(
            painter: DrawingPainter(
              baselinePath: baselinePath,
              userPoints: userPoints,
              showBaseline: showBaseline,
            ),
            size: Size(size, size),
          ),
        ),
      ),
    );
  }

  bool _isWithinCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dx <= size &&
        position.dy >= 0 &&
        position.dy <= size;
  }
}

class DrawingPainter extends CustomPainter {
  final Path? baselinePath;
  final List<DrawingPoint?> userPoints;
  final bool showBaseline;

  DrawingPainter({
    this.baselinePath,
    required this.userPoints,
    required this.showBaseline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw baseline (spiral or grid)
    if (showBaseline && baselinePath != null) {
      final baselinePaint = Paint()
        ..color = Colors.grey[400]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(baselinePath!, baselinePaint);
    }

    // Draw user's drawing with line breaks
    if (userPoints.isNotEmpty) {
      final userPaint = Paint()
        ..color = const Color(0xFF4A90E2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      Path? currentPath;

      for (int i = 0; i < userPoints.length; i++) {
        final point = userPoints[i];

        if (point == null) {
          // null이면 현재 경로를 그리고 새로 시작
          if (currentPath != null) {
            canvas.drawPath(currentPath, userPaint);
            currentPath = null;
          }
        } else {
          if (currentPath == null) {
            // 새 경로 시작
            currentPath = Path();
            currentPath.moveTo(point.x, point.y);
          } else {
            // 경로에 점 추가
            currentPath.lineTo(point.x, point.y);
          }
        }
      }

      // 마지막 경로 그리기
      if (currentPath != null) {
        canvas.drawPath(currentPath, userPaint);
      }

      // Draw points for visual feedback
      final pointPaint = Paint()
        ..color = const Color(0xFF4A90E2).withOpacity(0.3)
        ..style = PaintingStyle.fill;

      for (final point in userPoints) {
        if (point != null) {
          canvas.drawCircle(
            Offset(point.x, point.y),
            1.5,
            pointPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(DrawingPainter oldDelegate) {
    return userPoints.length != oldDelegate.userPoints.length ||
        baselinePath != oldDelegate.baselinePath;
  }
}

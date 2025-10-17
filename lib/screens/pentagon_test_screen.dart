import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../models/test_result.dart';
import '../widgets/drawing_canvas.dart';
import 'result_screen.dart';

class PentagonTestScreen extends StatefulWidget {
  const PentagonTestScreen({super.key});

  @override
  State<PentagonTestScreen> createState() => _PentagonTestScreenState();
}

class _PentagonTestScreenState extends State<PentagonTestScreen> {
  final List<DrawingPoint?> _points = [];
  int? _startTime;
  Timer? _samplingTimer;
  Offset? _lastPosition;

  // 가로 모드에 맞춰 캔버스 크기 조정
  static const double canvasWidth = 500.0; // 가로로 넓게
  static const double canvasHeight = 300.0; // 세로는 작게
  static const int samplingRateMs = 20;

  bool _isDrawing = false;
  bool _hasStarted = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // 가로 모드 강제
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 시스템 UI 숨기기 (전체 화면)
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();

    // 세로 모드로 복원
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // 시스템 UI 복원
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );

    super.dispose();
  }

  void _startDrawing(Offset position) {
    _isDrawing = true;
    if (!_hasStarted) {
      _hasStarted = true;
      _startTime = DateTime.now().millisecondsSinceEpoch;
      _startSampling();
    }
    _lastPosition = position;
  }

  void _updateDrawing(Offset position) {
    if (_isDrawing) {
      _lastPosition = position;
    }
  }

  void _stopDrawing() {
    _isDrawing = false;
    _lastPosition = null;
    _points.add(null);
    if (mounted) {
      setState(() {});
    }
  }

  void _startSampling() {
    _samplingTimer = Timer.periodic(
      const Duration(milliseconds: samplingRateMs),
      (timer) {
        if (_lastPosition != null && _hasStarted && _isDrawing) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          final point = DrawingPoint(
            x: _lastPosition!.dx,
            y: _lastPosition!.dy,
            normalizedX: _lastPosition!.dx / canvasWidth,
            normalizedY: _lastPosition!.dy / canvasHeight,
            timestamp: currentTime - _startTime!,
          );
          _points.add(point);
          _canvasKey.currentContext?.findRenderObject()?.markNeedsPaint();
        }
      },
    );
  }

  Future<void> _finishTest() async {
    _samplingTimer?.cancel();

    final validPoints = _points.whereType<DrawingPoint>().toList();

    if (validPoints.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 그림을 그려주세요')),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final result = await testProvider.analyzeTest(
      testType: TestType.pentagon,
      points: validPoints,
    );

    await testProvider.saveResult(result);

    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 헤더 (가로 모드용)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.white,
                  child: Row(
                    children: [
                      // 뒤로가기 버튼
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 8),
                      // 제목
                      const Expanded(
                        child: Text(
                          '오각형 따라 그리기 검사',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 메인 컨텐츠 영역
                Expanded(
                  child: Row(
                    children: [
                      // 왼쪽: 참고 이미지
                      Container(
                        width: 200,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A90E2).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                '참고 이미지',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4A90E2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFF4A90E2),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.asset(
                                  'assets/images/pentagon.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey[200],
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '이미지 없음',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '왼쪽 이미지를 보고\n오른쪽 캔버스에\n따라 그려주세요',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 구분선
                      Container(
                        width: 1,
                        color: Colors.grey[300],
                      ),

                      // 중앙: 그리기 캔버스
                      Expanded(
                        child: Center(
                          child: RepaintBoundary(
                            key: _canvasKey,
                            child: _WideDrawingCanvas(
                              width: canvasWidth,
                              height: canvasHeight,
                              userPoints: _points,
                              onPanStart: _startDrawing,
                              onPanUpdate: _updateDrawing,
                              onPanEnd: _stopDrawing,
                            ),
                          ),
                        ),
                      ),

                      // 오른쪽: 완료 버튼
                      Container(
                        width: 100,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 120,
                              child: ElevatedButton(
                                onPressed: _hasStarted ? _finishTest : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4A90E2),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey[300],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  '완료',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 가로로 넓은 캔버스 위젯
class _WideDrawingCanvas extends StatelessWidget {
  final double width;
  final double height;
  final List<DrawingPoint?> userPoints;
  final Function(Offset) onPanStart;
  final Function(Offset) onPanUpdate;
  final Function() onPanEnd;

  const _WideDrawingCanvas({
    required this.width,
    required this.height,
    required this.userPoints,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A90E2), width: 3),
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
            painter: _WideDrawingPainter(userPoints: userPoints),
            size: Size(width, height),
          ),
        ),
      ),
    );
  }

  bool _isWithinCanvas(Offset position) {
    return position.dx >= 0 &&
        position.dx <= width &&
        position.dy >= 0 &&
        position.dy <= height;
  }
}

// 가로 캔버스용 페인터
class _WideDrawingPainter extends CustomPainter {
  final List<DrawingPoint?> userPoints;

  _WideDrawingPainter({required this.userPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (userPoints.isEmpty) return;

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
        if (currentPath != null) {
          canvas.drawPath(currentPath, userPaint);
          currentPath = null;
        }
      } else {
        if (currentPath == null) {
          currentPath = Path();
          currentPath.moveTo(point.x, point.y);
        } else {
          currentPath.lineTo(point.x, point.y);
        }
      }
    }

    if (currentPath != null) {
      canvas.drawPath(currentPath, userPaint);
    }

    // 점 표시
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

  @override
  bool shouldRepaint(_WideDrawingPainter oldDelegate) {
    return userPoints.length != oldDelegate.userPoints.length;
  }
}

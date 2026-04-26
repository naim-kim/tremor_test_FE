import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../models/test_result.dart';
import 'result_screen.dart';
import '../theme/app_colors.dart';

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

  static const double canvasWidth = 500.0;
  static const double canvasHeight = 300.0;
  static const int samplingRateMs = 20;

  bool _isDrawing = false;
  bool _hasStarted = false;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
    if (_isDrawing) _lastPosition = position;
  }

  void _stopDrawing() {
    _isDrawing = false;
    _lastPosition = null;
    _points.add(null);
    if (mounted) setState(() {});
  }

  void _startSampling() {
    _samplingTimer = Timer.periodic(
      const Duration(milliseconds: samplingRateMs),
      (timer) {
        if (_lastPosition != null && _hasStarted && _isDrawing) {
          final currentTime = DateTime.now().millisecondsSinceEpoch;
          _points.add(DrawingPoint(
            x: _lastPosition!.dx,
            y: _lastPosition!.dy,
            normalizedX: _lastPosition!.dx / canvasWidth,
            normalizedY: _lastPosition!.dy / canvasHeight,
            timestamp: currentTime - _startTime!,
          ));
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
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiClient = Provider.of<ApiClient>(context, listen: false);
    final backendUserId = userProvider.userId;
    if (backendUserId == null) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('먼저 회원가입/로그인을 해주세요.')));
      return;
    }
    final result = await testProvider.analyzeTest(
      testType: TestType.pentagon,
      points: validPoints,
    );
    List<int>? imageBytes;
    try {
      final RenderRepaintBoundary? boundary = _canvasKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
        final ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) imageBytes = byteData.buffer.asUint8List();
      }
    } catch (e) {
      debugPrint('Failed to capture image: $e');
    }
    await testProvider.saveResult(
      result,
      backendUserId: backendUserId,
      apiClient: apiClient,
      pixelsPerMm: userProvider.pixelsPerMm,
      imageBytes: imageBytes,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ResultScreen(result: result)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.black.withOpacity(0.08), width: 0.5),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 14, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '오각형 그리기 검사',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A18),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Main row ─────────────────────────────────────────────
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Reference panel
                    Container(
                      width: 150,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.black.withOpacity(0.06), width: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '참고 이미지',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              'assets/images/pentagon.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                height: 90,
                                color: const Color(0xFFF2F3F7),
                                child: Center(
                                  child: Icon(Icons.pentagon_outlined,
                                      size: 44, color: Colors.grey[300]),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '위 그림을 보고\n아래 칸에 그려주세요',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Canvas
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 0.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
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
                    ),

                    const SizedBox(width: 10),

                    // Done panel
                    SizedBox(
                      width: 66,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _hasStarted ? '완료 후\n버튼 클릭' : '그리기\n시작',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _hasStarted ? _finishTest : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal800,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    AppColors.teal800.withOpacity(0.25),
                                elevation: 0,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('완료'),
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
        ),
      ),
    );
  }
}

// ── Drawing canvas ────────────────────────────────────────────────────────────

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.globalPosition);
            if (_inBounds(local, constraints)) onPanStart(local);
          },
          onPanUpdate: (details) {
            final RenderBox box = context.findRenderObject() as RenderBox;
            final local = box.globalToLocal(details.globalPosition);
            if (_inBounds(local, constraints)) onPanUpdate(local);
          },
          onPanEnd: (_) => onPanEnd(),
          child: CustomPaint(
            painter: _WideDrawingPainter(userPoints: userPoints),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          ),
        );
      },
    );
  }

  bool _inBounds(Offset p, BoxConstraints c) =>
      p.dx >= 0 && p.dx <= c.maxWidth && p.dy >= 0 && p.dy <= c.maxHeight;
}

class _WideDrawingPainter extends CustomPainter {
  final List<DrawingPoint?> userPoints;
  _WideDrawingPainter({required this.userPoints});

  @override
  void paint(Canvas canvas, Size size) {
    if (userPoints.isEmpty) return;
    final paint = Paint()
      ..color = AppColors.teal800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    Path? path;
    for (final point in userPoints) {
      if (point == null) {
        if (path != null) {
          canvas.drawPath(path, paint);
          path = null;
        }
      } else {
        if (path == null) {
          path = Path()..moveTo(point.x, point.y);
        } else {
          path.lineTo(point.x, point.y);
        }
      }
    }
    if (path != null) canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WideDrawingPainter old) =>
      userPoints.length != old.userPoints.length;
}

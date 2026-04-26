import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import '../models/test_result.dart';
import '../widgets/drawing_canvas.dart';
import '../utils/spiral_generator.dart';
import 'result_screen.dart';
import '../theme/app_colors.dart';

class SpiralTestScreen extends StatefulWidget {
  const SpiralTestScreen({super.key});

  @override
  State<SpiralTestScreen> createState() => _SpiralTestScreenState();
}

class _SpiralTestScreenState extends State<SpiralTestScreen> {
  final List<DrawingPoint?> _points = [];
  int? _startTime;
  Timer? _samplingTimer;
  Offset? _lastPosition;

  static const double canvasSize = 300.0;
  static const int samplingRateMs = 20;

  bool _isDrawing = false;
  bool _hasStarted = false;

  @override
  void dispose() {
    _samplingTimer?.cancel();
    super.dispose();
  }

  void _startDrawing(Offset position) {
    setState(() {
      _isDrawing = true;
      if (!_hasStarted) {
        _hasStarted = true;
        _startTime = DateTime.now().millisecondsSinceEpoch;
        _startSampling();
      }
      _lastPosition = position;
    });
  }

  void _updateDrawing(Offset position) {
    if (_isDrawing) setState(() => _lastPosition = position);
  }

  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
      _lastPosition = null;
      _points.add(null);
    });
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
            normalizedX: _lastPosition!.dx / canvasSize,
            normalizedY: _lastPosition!.dy / canvasSize,
            timestamp: currentTime - _startTime!,
          ));
        }
      },
    );
  }

  Future<void> _finishTest() async {
    _samplingTimer?.cancel();
    final validPoints = _points.whereType<DrawingPoint>().toList();
    if (validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 그림을 그려주세요')),
      );
      return;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 회원가입/로그인을 해주세요.')),
      );
      return;
    }
    final result = await testProvider.analyzeTest(
      testType: TestType.spiral,
      points: validPoints,
    );
    await testProvider.saveResult(
      result,
      backendUserId: backendUserId,
      apiClient: apiClient,
      pixelsPerMm: userProvider.pixelsPerMm,
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // ── App bar ──────────────────────────────────────────────
              Row(
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
                            color: Colors.black.withOpacity(0.08), width: 0.5),
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 15, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '나선 그리기 검사',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A18),
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Instruction ──────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 15, color: AppColors.teal800),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        '나선을 따라 최대한 정확하게 그려주세요',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.teal800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Canvas ───────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.black.withOpacity(0.06), width: 0.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: DrawingCanvas(
                        size: canvasSize,
                        baselinePath:
                            SpiralGenerator.generateSpiralPath(canvasSize),
                        userPoints: _points,
                        onPanStart: _startDrawing,
                        onPanUpdate: _updateDrawing,
                        onPanEnd: _stopDrawing,
                        showBaseline: true,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Status ───────────────────────────────────────────────
              Text(
                _hasStarted ? '그리기 완료 후 아래 버튼을 누르세요' : '캔버스를 터치해 시작하세요',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),

              const SizedBox(height: 10),

              // ── Button ───────────────────────────────────────────────
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
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('완료'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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

class SpiralTestScreen extends StatefulWidget {
  const SpiralTestScreen({super.key});

  @override
  State<SpiralTestScreen> createState() => _SpiralTestScreenState();
}

class _SpiralTestScreenState extends State<SpiralTestScreen> {
  // Design Constants
  static const _gradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const _primaryColor = Color(0xFF667eea);

  final List<DrawingPoint?> _points = []; // null을 포함하도록 변경
  int? _startTime;
  Timer? _samplingTimer;
  Offset? _lastPosition;

  static const double canvasSize = 300.0;
  static const int samplingRateMs = 20; // 50Hz = 20ms interval

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
    if (_isDrawing) {
      setState(() {
        _lastPosition = position;
      });
    }
  }

  void _stopDrawing() {
    setState(() {
      _isDrawing = false;
      _lastPosition = null;
      // 선을 끊기 위해 null 추가
      _points.add(null);
    });
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
            normalizedX: _lastPosition!.dx / canvasSize,
            normalizedY: _lastPosition!.dy / canvasSize,
            timestamp: currentTime - _startTime!,
          );
          _points.add(point);
        }
      },
    );
  }

  Future<void> _finishTest() async {
    _samplingTimer?.cancel();

    // null 값 제거하여 실제 포인트만 전달
    final validPoints = _points.whereType<DrawingPoint>().toList();

    if (validPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('먼저 그림을 그려주세요'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );

    // Calculate results
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final apiClient = Provider.of<ApiClient>(context, listen: false);

    final backendUserId = userProvider.userId;
    if (backendUserId == null) {
      if (!mounted) return;
      Navigator.of(context).pop(); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('먼저 회원가입/로그인을 해주세요.'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    final result = await testProvider.analyzeTest(
      testType: TestType.spiral,
      points: validPoints,
    );

    // Save result locally and sync to backend (CSV export happens on backend).
    await testProvider.saveResult(
      result,
      backendUserId: backendUserId,
      apiClient: apiClient,
      pixelsPerMm: userProvider.pixelsPerMm,
    );

    if (!mounted) return;

    // Close loading dialog
    Navigator.of(context).pop();

    // Navigate to result screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(result: result),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '나선 그리기 검사',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Instructions
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      '나선을 따라 그려주세요',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '선을 최대한 정확하게 따라가세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),

              // Drawing Canvas
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
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

              // Finish Button
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: _hasStarted
                        ? LinearGradient(
                            colors: [
                              Colors.white,
                              Colors.white.withOpacity(0.95)
                            ],
                          )
                        : null,
                    color: _hasStarted ? null : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _hasStarted
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: ElevatedButton(
                    onPressed: _hasStarted ? _finishTest : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      '완료',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _hasStarted
                            ? _primaryColor
                            : Colors.white.withOpacity(0.5),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

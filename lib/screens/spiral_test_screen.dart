import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/test_provider.dart';
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
  final List<DrawingPoint> _points = [];
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
    });
  }

  void _startSampling() {
    _samplingTimer = Timer.periodic(
      const Duration(milliseconds: samplingRateMs),
      (timer) {
        if (_lastPosition != null && _hasStarted) {
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

    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 그림을 그려주세요')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Calculate results
    final testProvider = Provider.of<TestProvider>(context, listen: false);
    final result = await testProvider.analyzeTest(
      testType: TestType.spiral,
      points: _points,
    );

    // Save result
    await testProvider.saveResult(result);

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
      appBar: AppBar(
        title: const Text('나선 그리기 검사'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instructions
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    '나선을 따라 그려주세요',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '선을 최대한 정확하게 따라가세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Drawing Canvas
            Expanded(
              child: Center(
                child: DrawingCanvas(
                  size: canvasSize,
                  baselinePath: SpiralGenerator.generateSpiralPath(canvasSize),
                  userPoints: _points,
                  onPanStart: _startDrawing,
                  onPanUpdate: _updateDrawing,
                  onPanEnd: _stopDrawing,
                  showBaseline: true,
                ),
              ),
            ),

            // Finish Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
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
            ),
          ],
        ),
      ),
    );
  }
}

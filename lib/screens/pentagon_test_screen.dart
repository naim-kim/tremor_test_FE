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
  final List<DrawingPoint> _points = [];
  int? _startTime;
  Timer? _samplingTimer;
  Offset? _lastPosition;

  static const double canvasSize = 300.0;
  static const int samplingRateMs = 20; // 50Hz = 20ms interval

  bool _isDrawing = false;
  bool _hasStarted = false;
  bool _isReferenceExpanded = false;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    _samplingTimer?.cancel();
    // Restore portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
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
      testType: TestType.pentagon,
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
        title: const Text('오각형 따라 그리기 검사'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Drawing Canvas
                Expanded(
                  flex: 2,
                  child: Center(
                    child: DrawingCanvas(
                      size: canvasSize,
                      userPoints: _points,
                      onPanStart: _startDrawing,
                      onPanUpdate: _updateDrawing,
                      onPanEnd: _stopDrawing,
                      showBaseline: false,
                    ),
                  ),
                ),

                // Finish Button (vertical)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: _hasStarted ? _finishTest : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A90E2),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const RotatedBox(
                        quarterTurns: 3,
                        child: Text(
                          '완료',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Reference Image (toggleable)
            Positioned(
              top: 16,
              right: 120,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isReferenceExpanded = !_isReferenceExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isReferenceExpanded ? 200 : 100,
                  height: _isReferenceExpanded ? 200 : 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/pentagon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isReferenceExpanded
                                  ? Icons.zoom_in
                                  : Icons.zoom_out,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
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

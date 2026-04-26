import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _controller = TextEditingController();
  final double _markerPixelDistance = 200.0;
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final mm = double.tryParse(text);
    if (mm == null || mm <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 숫자를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final pixelsPerMm = _markerPixelDistance / mm;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setPixelsPerMm(pixelsPerMm);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('화면 보정 값이 저장되었습니다.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('화면 보정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Instructions card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.teal800.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: AppColors.teal800, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '보정 방법',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2C2A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _InstructionStep(
                      number: '1',
                      text: '아래 두 표시 사이의 거리를 자로 직접 측정해주세요.',
                    ),
                    const SizedBox(height: 10),
                    _InstructionStep(
                      number: '2',
                      text: '측정한 실제 거리를 밀리미터(mm) 단위로 입력한 후 저장을 눌러주세요.',
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.amber50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tips_and_updates_outlined,
                              size: 16, color: AppColors.amber600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '이 값은 픽셀을 mm로 변환할 때 사용됩니다.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.amber600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Ruler / marker widget ──────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Markers + line
                    SizedBox(
                      width: _markerPixelDistance + 16,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Dashed line
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.center,
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.teal800.withOpacity(0.3),
                                      AppColors.teal800.withOpacity(0.7),
                                      AppColors.teal800.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              _CalibrationMarker(),
                              _CalibrationMarker(),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '위 두 표시 사이의 거리를 자로 측정하세요',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Input card ────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2C2A),
                  ),
                  decoration: const InputDecoration(
                    labelText: '측정한 거리 (mm)',
                    suffixText: 'mm',
                    suffixStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal800,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Save button ───────────────────────────────────────
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
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

// ── Instruction step ──────────────────────────────────────────────────────────

class _InstructionStep extends StatelessWidget {
  final String number;
  final String text;
  const _InstructionStep({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.teal800,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Calibration marker ────────────────────────────────────────────────────────

class _CalibrationMarker extends StatelessWidget {
  const _CalibrationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.teal800,
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal800.withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class CalibrationScreen extends StatefulWidget {
  const CalibrationScreen({super.key});

  @override
  State<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends State<CalibrationScreen> {
  final _controller = TextEditingController();
  final double _markerPixelDistance = 200.0; // logical pixels between markers
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

    setState(() {
      _isSaving = true;
    });

    try {
      // pixelsPerMm = pixels / mm
      final pixelsPerMm = _markerPixelDistance / mm;
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.setPixelsPerMm(pixelsPerMm);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('화면 보정 값이 저장되었습니다.')),
      );
      Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('화면 보정'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '1. 아래 두 표시 사이의 거리를 자로 직접 측정해주세요.\n'
                '2. 측정한 실제 거리를 밀리미터(mm) 단위로 입력한 후 저장을 눌러주세요.\n\n'
                '※ 이 값은 픽셀을 mm로 변환할 때 사용됩니다.',
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: _markerPixelDistance + 40,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          _CalibrationMarker(),
                          _CalibrationMarker(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('여기 사이 거리를 자로 측정하세요'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '측정한 거리 (mm)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          '저장',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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

class _CalibrationMarker extends StatelessWidget {
  const _CalibrationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}



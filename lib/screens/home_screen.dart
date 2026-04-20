import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/test_provider.dart';
import '../models/test_result.dart';
import 'spiral_test_screen.dart';
import 'pentagon_test_screen.dart';
import 'my_page_screen.dart';
import 'result_screen.dart';
import 'all_results_screen.dart';
import '../theme/app_colors.dart';

String _compactCategory(String value) {
  final head = value.split(':').first.trim();
  return head.isEmpty ? value : head;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final testProvider = Provider.of<TestProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── App bar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '오늘의 검사',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[500],
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${userProvider.userName}님, 안녕하세요 👋',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A18),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyPageScreen()),
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.08),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Test cards ─────────────────────────────────────────────
              _TestCard(
                title: '나선 그리기',
                subtitle: 'Spiral drawing test',
                icon: Icons.refresh_rounded,
                accentColor: AppColors.teal800,
                accentLight: const Color(0xFFE1F5EE),
                lastResult: testProvider.getLatestResult(TestType.spiral),
                onTestPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SpiralTestScreen()),
                ),
                onResultPressed: (result) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ResultScreen(result: result)),
                ),
              ),

              const SizedBox(height: 12),

              _TestCard(
                title: '오각형 그리기',
                subtitle: 'Pentagon drawing test',
                icon: Icons.pentagon_outlined,
                accentColor: AppColors.teal600,
                accentLight: const Color(0xFFE1F5EE),
                lastResult: testProvider.getLatestResult(TestType.pentagon),
                onTestPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PentagonTestScreen()),
                ),
                onResultPressed: (result) => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ResultScreen(result: result)),
                ),
              ),

              const SizedBox(height: 20),

              // ── All results ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllResultsScreen()),
                  ),
                  icon: Icon(Icons.access_time_rounded,
                      size: 15, color: Colors.grey[500]),
                  label: Text(
                    '모든 기록 보기',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(
                        color: Colors.black.withOpacity(0.10), width: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
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

// ── Test card ─────────────────────────────────────────────────────────────────

class _TestCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color accentLight;
  final TestResult? lastResult;
  final VoidCallback onTestPressed;
  final Function(TestResult) onResultPressed;

  const _TestCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.accentLight,
    required this.lastResult,
    required this.onTestPressed,
    required this.onResultPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A18),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                // Score or status pill
                if (lastResult != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${lastResult!.overallScore.toStringAsFixed(0)}점',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F3F7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '미완료',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Info bar ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FA),
                borderRadius: BorderRadius.circular(10),
              ),
              child: lastResult != null
                  ? Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '최근 결과',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _compactCategory(lastResult!.resultCategory),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A18),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text(
                          '아직 검사 기록이 없어요',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
            ),
          ),

          // ── Action buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: lastResult != null
                ? Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () => onResultPressed(lastResult!),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1A1A18),
                              side: BorderSide(
                                color: Colors.black.withOpacity(0.12),
                                width: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const Text('결과 보기'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: onTestPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            child: const Text('다시 검사'),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: onTestPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      child: const Text('검사 시작하기'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

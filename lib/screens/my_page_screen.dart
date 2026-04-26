import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/test_provider.dart';
import '../models/test_result.dart';
import 'result_screen.dart';
import 'login_screen.dart';
import 'calibration_screen.dart';
import '../theme/app_colors.dart';

String _compactCategory(String value) {
  final head = value.split(':').first.trim();
  return head.isEmpty ? value : head;
}

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final testProvider = Provider.of<TestProvider>(context);
    final allResults = testProvider.allResults;

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
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                          Icons.arrow_back_ios_new_rounded,
                          size: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '마이 페이지',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A18),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CalibrationScreen()),
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
                          Icons.tune_rounded,
                          size: 17,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Profile card ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.teal800,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.15),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 26, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userProvider.userName}님',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userProvider.userEmail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userProvider.loginProvider == 'kakao'
                            ? '카카오'
                            : 'Google',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Stat cards ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.refresh_rounded,
                      label: '나선 검사',
                      count:
                          testProvider.getResultsByType(TestType.spiral).length,
                      color: AppColors.teal800,
                      lightColor: const Color(0xFFE1F5EE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pentagon_outlined,
                      label: '오각형 검사',
                      count: testProvider
                          .getResultsByType(TestType.pentagon)
                          .length,
                      color: AppColors.teal600,
                      lightColor: const Color(0xFFE1F5EE),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── History header ─────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    '검사 기록',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A18),
                      letterSpacing: -0.2,
                    ),
                  ),
                  if (allResults.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showClearDialog(context, testProvider),
                      child: Text(
                        '전체 삭제',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              if (allResults.isEmpty)
                _EmptyHistory()
              else
                ...allResults.map(
                  (result) => _TestHistoryItem(
                    result: result,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ResultScreen(result: result)),
                    ),
                    onDelete: () => testProvider.deleteResult(result.id),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Logout ─────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, userProvider),
                  icon: Icon(Icons.logout_rounded,
                      size: 16, color: Colors.red.shade400),
                  label: Text(
                    '로그아웃',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.red.shade400,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red.shade200, width: 0.5),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('로그아웃'),
        content: const Text('로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              userProvider.logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, TestProvider testProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('전체 삭제'),
        content: const Text('모든 검사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              testProvider.clearAllResults();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('모든 기록이 삭제되었습니다')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color lightColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.lightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              const SizedBox(height: 1),
              Text(
                '$count회',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 32, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            '검사 기록이 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '첫 번째 검사를 시작해 보세요',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// ── History item ──────────────────────────────────────────────────────────────

class _TestHistoryItem extends StatelessWidget {
  final TestResult result;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TestHistoryItem({
    required this.result,
    required this.onTap,
    required this.onDelete,
  });

  bool get _isSpiral => result.testType == TestType.spiral;
  IconData get _icon =>
      _isSpiral ? Icons.refresh_rounded : Icons.pentagon_outlined;
  String get _testName => _isSpiral ? '나선 그리기' : '오각형 그리기';
  Color get _color => _isSpiral ? AppColors.teal800 : AppColors.teal600;
  Color get _lightColor => const Color(0xFFE1F5EE);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _lightColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: _color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _testName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A18),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm').format(result.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${result.overallScore.toStringAsFixed(0)}점',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _color,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _lightColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _compactCategory(result.resultCategory),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Icon(Icons.delete_outline_rounded,
                  size: 18, color: Colors.grey[350]),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('기록 삭제'),
        content: const Text('이 검사 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

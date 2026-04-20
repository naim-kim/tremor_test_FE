import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../theme/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),

              // ── Logo & title ─────────────────────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5EE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.assessment_rounded,
                  size: 26,
                  color: AppColors.teal800,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '떨림 검사',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A18),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '간편하고 정확한 떨림 측정',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(flex: 2),

              // ── Buttons ──────────────────────────────────────────────
              _LoginButton(
                onTap: () => _showComingSoon(context),
                backgroundColor: const Color(0xFFFEE500),
                textColor: const Color(0xFF1A1A18),
                icon: Icons.chat_bubble_rounded,
                label: '카카오 로그인',
              ),
              const SizedBox(height: 10),
              _LoginButton(
                onTap: () => _showComingSoon(context),
                backgroundColor: const Color(0xFFF7F8FA),
                textColor: const Color(0xFF1A1A18),
                icon: Icons.g_mobiledata_rounded,
                label: '구글 로그인',
              ),

              const SizedBox(height: 20),

              // ── Signup link ──────────────────────────────────────────
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          const SignupScreen(initialProvider: 'manual'),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      children: [
                        const TextSpan(text: '이메일로 '),
                        TextSpan(
                          text: '회원가입',
                          style: TextStyle(
                            color: AppColors.teal800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // ── Terms ────────────────────────────────────────────────
              Center(
                child: Text(
                  '로그인하시면 서비스 이용약관 및 개인정보 처리방침에 동의하게 됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('곧 출시됩니다'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String label;

  const _LoginButton({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textColor,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

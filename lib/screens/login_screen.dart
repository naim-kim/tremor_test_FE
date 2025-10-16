import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Title
              const Icon(
                Icons.assessment,
                size: 80,
                color: Color(0xFF4A90E2),
              ),
              const SizedBox(height: 24),
              const Text(
                '떨림 검사',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '간편하고 정확한 떨림 측정',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 80),

              // Kakao Login Button
              _LoginButton(
                onTap: () => _handleLogin(context, 'kakao'),
                backgroundColor: const Color(0xFFFEE500),
                textColor: Colors.black87,
                icon: Icons.chat_bubble,
                text: '카카오톡으로 시작하기',
              ),
              const SizedBox(height: 16),

              // Google Login Button
              _LoginButton(
                onTap: () => _handleLogin(context, 'google'),
                backgroundColor: Colors.white,
                textColor: Colors.black87,
                icon: Icons.g_mobiledata,
                text: 'Google로 시작하기',
                hasBorder: true,
              ),

              const SizedBox(height: 32),
              const Text(
                '로그인하시면 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLogin(BuildContext context, String provider) {
    // Placeholder login - just set user data and navigate
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setUser(
      name: '테스트',
      email: 'test@example.com',
      loginProvider: provider,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final String text;
  final bool hasBorder;

  const _LoginButton({
    required this.onTap,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.text,
    this.hasBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            border: hasBorder ? Border.all(color: Colors.grey.shade300) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 24),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

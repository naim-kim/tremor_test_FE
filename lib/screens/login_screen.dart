import 'package:flutter/material.dart';
import 'signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // Design Constants
  static const _gradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const _horizontalPadding = 32.0;
  static const _borderRadius = 16.0;
  static const _buttonHeight = 60.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildLogo(),
                const SizedBox(height: 32),
                _buildTitle(),
                const Spacer(),
                _buildLoginButtons(context),
                const SizedBox(height: 16),
                _buildTermsText(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.assessment,
        size: 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    return const Column(
      children: [
        Text(
          '떨림 검사',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '간편하고 정확한 떨림 측정',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LoginButton(
          onTap: () => _showComingSoon(context),
          backgroundColor: const Color(0xFFFEE500),
          textColor: Colors.black87,
          icon: Icons.chat_bubble_rounded,
          text: '카카오 로그인',
        ),
        const SizedBox(height: 12),
        _LoginButton(
          onTap: () => _showComingSoon(context),
          backgroundColor: Colors.white,
          textColor: Colors.black87,
          icon: Icons.g_mobiledata_rounded,
          text: 'Google 로그인',
          hasBorder: true,
        ),
        const SizedBox(height: 24),
        _buildSignupLink(context),
      ],
    );
  }

  Widget _buildSignupLink(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigateToSignup(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '이메일로 ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const Text(
              '회원가입',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: Colors.white,
                decorationThickness: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      '로그인하시면 서비스 이용약관 및\n개인정보 처리방침에 동의하게 됩니다.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withOpacity(0.7),
        height: 1.5,
      ),
    );
  }

  void _navigateToSignup(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SignupScreen(initialProvider: 'manual'),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('곧 출시됩니다'),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
      borderRadius: BorderRadius.circular(16),
      elevation: hasBorder ? 0 : 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            border: hasBorder
                ? Border.all(color: Colors.grey.shade200, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 28),
              const SizedBox(width: 12),
              Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

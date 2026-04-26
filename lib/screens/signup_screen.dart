import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import 'home_screen.dart';
import '../theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  final String initialProvider;

  const SignupScreen({
    super.key,
    this.initialProvider = 'manual',
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  late String _provider;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _provider = widget.initialProvider;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Nav bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F3F7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 15,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '환영합니다',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A18),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '정보를 입력하고 시작하세요',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[500],
                        ),
                      ),

                      const SizedBox(height: 36),

                      // ── Name field ─────────────────────────────────
                      _FieldLabel(label: '이름'),
                      const SizedBox(height: 8),
                      _CustomTextField(
                        controller: _nameController,
                        hint: '이름을 입력해주세요',
                        icon: Icons.person_outline_rounded,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이름을 입력해주세요';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // ── Email field ────────────────────────────────
                      _FieldLabel(label: '이메일'),
                      const SizedBox(height: 8),
                      _CustomTextField(
                        controller: _emailController,
                        hint: '이메일을 입력해주세요',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '이메일을 입력해주세요';
                          }
                          if (!value.contains('@')) {
                            return '올바른 이메일 형식을 입력해주세요';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 36),

                      // ── Submit ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal800,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                AppColors.teal800.withOpacity(0.3),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text('회원가입 및 계속하기'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final apiClient = Provider.of<ApiClient>(context, listen: false);
      await userProvider.loginAndSync(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        loginProvider: _provider,
        apiClient: apiClient,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMessage = '회원가입 실패';
      if (e.toString().contains('409') ||
          e.toString().contains('already exists')) {
        errorMessage = '이미 사용 중인 이메일입니다';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = '네트워크 연결을 확인해주세요';
      }
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showErrorSnackBar(String message) {
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1A18),
        letterSpacing: -0.1,
      ),
    );
  }
}

// ── Text field ────────────────────────────────────────────────────────────────

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator?.call(controller.text),
      builder: (FormFieldState<String> field) {
        final hasError = field.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              onChanged: (v) => field.didChange(v),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF1A1A18),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400]),
                prefixIcon: Icon(
                  icon,
                  size: 18,
                  color: hasError ? Colors.red.shade400 : Colors.grey[400],
                ),
                filled: true,
                fillColor: const Color(0xFFF7F8FA),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: hasError
                      ? BorderSide(color: Colors.red.shade300, width: 1)
                      : BorderSide(
                          color: Colors.black.withOpacity(0.07), width: 0.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? Colors.red.shade400 : AppColors.teal800,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            if (hasError) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 14, color: Colors.red.shade400),
                  const SizedBox(width: 5),
                  Text(
                    field.errorText ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/api_client.dart';
import 'home_screen.dart';

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
  // Design Constants
  static const _gradientColors = [Color(0xFF667eea), Color(0xFF764ba2)];
  static const _primaryColor = Color(0xFF667eea);
  static const _horizontalPadding = 32.0;
  static const _borderRadius = 16.0;
  static const _buttonHeight = 60.0;

  // Form State
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
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _gradientColors,
          ),
        ),
        child: SafeArea(
          child: _buildForm(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: const Text(
        '회원 가입',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(_horizontalPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - (_horizontalPadding * 2),
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      _buildWelcomeText(),
                      const SizedBox(height: 40),
                      _buildNameField(),
                      const SizedBox(height: 16),
                      _buildEmailField(),
                      const Spacer(flex: 2),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '환영합니다',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '정보를 입력하고 시작하세요',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return _CustomTextField(
      controller: _nameController,
      hint: '이름을 입력해주세요',
      icon: Icons.person_outline_rounded,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '이름을 입력해주세요';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return _CustomTextField(
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
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: _buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.white.withOpacity(0.95)],
        ),
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            : const Text(
                '회원가입 및 계속하기',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                  letterSpacing: -0.3,
                ),
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

      // Parse error message
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
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    // Dismiss keyboard to make room for SnackBar
    FocusScope.of(context).unfocus();

    // Small delay to allow keyboard to dismiss
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
}

// Custom Text Field Widget
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

  static const _primaryColor = Color(0xFF667eea);
  static const _borderRadius = 16.0;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => validator?.call(controller.text),
      builder: (FormFieldState<String> field) {
        final hasError = field.hasError;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_borderRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (value) => field.didChange(value),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: hasError ? Colors.red.shade300 : Colors.grey.shade400,
              ),
              prefixIcon: Icon(
                icon,
                color: hasError ? Colors.red.shade300 : _primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
                borderSide: hasError
                    ? BorderSide(color: Colors.red.shade300, width: 2)
                    : BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(_borderRadius),
                borderSide: BorderSide(
                  color: hasError ? Colors.red.shade400 : _primaryColor,
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}

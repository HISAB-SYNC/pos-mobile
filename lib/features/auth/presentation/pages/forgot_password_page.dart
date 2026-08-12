import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_split_scaffold.dart';
import 'otp_verification_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final error = await auth.requestPasswordReset(email);

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OtpVerificationPage(email: email)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSplitScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthBackButton(),
            const SizedBox(height: 12),
            const Text(
              'Forgot Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "Enter your registered email address, we'll send you a code to reset your password.",
              style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 24),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(text: 'Email'),
                  TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: authFieldDecoration(),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Reset password',
              isLoading: auth.isBusy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_split_scaffold.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({super.key, required this.email, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();
    final error = await auth.resetPassword(
      widget.email,
      widget.resetToken,
      _passwordController.text,
    );

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    // Success — clear the whole stack and go back to login.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password reset successful. Please log in.')),
    );
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  Widget _label(String text) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: AppColors.textDark,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: text),
          const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
        ],
      ),
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
              'Set new password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Your new password should be different to previous one',
              style: TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
            ),
            const SizedBox(height: 20),
            _label('new password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure1,
              decoration: authFieldDecoration().copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure1 ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Password is required';
                if (value.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),
            const SizedBox(height: 18),
            _label('Confirm password'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure2,
              decoration: authFieldDecoration().copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure2 ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please confirm your password';
                if (value != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Confirm password',
              isLoading: auth.isBusy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
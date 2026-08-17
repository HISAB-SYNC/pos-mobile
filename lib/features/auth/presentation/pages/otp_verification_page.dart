import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../provider/auth_provider.dart';
import '../widgets/auth_split_scaffold.dart';
import 'reset_password_page.dart';

/// Matches POST /auth/reset-password/verify — a real 6-digit numeric OTP,
/// checked here. On success the provider stores a resetToken internally,
/// which ResetPasswordPage uses without needing email passed along.
class OtpVerificationPage extends StatefulWidget {
  final String email;

  const OtpVerificationPage({super.key, required this.email});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  static const int _codeLength = 6;
  static const int _resendSeconds = 120;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = _resendSeconds;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 0) {
        timer.cancel();
        return;
      }
      setState(() => _secondsLeft--);
    });
  }

  String get _formattedTime {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(1, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedEmail {
    final parts = widget.email.split('@');
    if (parts.length != 2 || parts[0].isEmpty) return widget.email;
    final visible = parts[0].substring(0, 1);
    return '$visible****@${parts[1]}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resend() async {
    if (_secondsLeft > 0) return;
    final auth = context.read<AuthProvider>();
    await auth.requestPasswordReset(widget.email);
    if (!mounted) return;
    _startTimer();
  }

  Future<void> _verify() async {
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != _codeLength) {
      setState(() => _errorMessage = 'Enter the full 6-digit code');
      return;
    }

    setState(() => _errorMessage = null);
    final auth = context.read<AuthProvider>();
    final error = await auth.verifyResetOtp(widget.email, otp);

    if (!mounted) return;

    if (error != null) {
      setState(() => _errorMessage = error);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthSplitScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthBackButton(),
          const SizedBox(height: 12),
          const Text(
            'Enter OTP',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'We have shared a code of your $_maskedEmail email address.',
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_codeLength, (index) {
              return SizedBox(
                width: 42,
                height: 48,
                child: TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.borderGrey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppColors.navy, width: 1.4),
                    ),
                  ),
                  onChanged: (value) => _onDigitChanged(index, value),
                ),
              );
            }),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          AuthPrimaryButton(
            label: 'verify',
            isLoading: auth.isBusy,
            onPressed: _verify,
          ),
          const SizedBox(height: 12),
          Center(
            child: _secondsLeft > 0
                ? Text(
                    'Resend code in $_formattedTime',
                    style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                  )
                : TextButton(
                    onPressed: _resend,
                    child: const Text(
                      'Resend code',
                      style: TextStyle(fontSize: 13, color: AppColors.navy, fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
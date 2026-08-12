import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

const String kAuthLogoAsset = 'assets/images/andalus11.png';

/// Shared shell for every auth screen (login, forgot password, OTP,
/// reset password). Wide screens show the big logo on the left and
/// your [child] content on the right, matching the design. Phones
/// just show [child] centered with a small logo on top of it.
///
/// Usage: wrap each screen's content in this, and put your own
/// "Back" button + title + form inside [child] — this widget only
/// handles the outer split-panel layout, nothing else.
class AuthSplitScaffold extends StatelessWidget {
  final Widget child;

  const AuthSplitScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            if (isWide) {
              return Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        kAuthLogoAsset,
                        width: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: child,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset(
                          kAuthLogoAsset,
                          height: 70,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The "< Back" link used at the top of every auth screen except login.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(),
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chevron_left, size: 20, color: AppColors.textDark),
            Text(
              'Back',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Consistent field decoration reused across forgot/OTP/reset screens.
InputDecoration authFieldDecoration() {
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
  );
}

/// Consistent navy primary button reused across forgot/OTP/reset screens.
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/login_form_widget.dart';
import 'package:provider/provider.dart';
import '../../../../features/auth/provider/auth_provider.dart';

const String kLogoAsset = 'assets/images/andalus11.png';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                // Wide screens (tablet/web) get the split layout from the design
                // (big decorative logo on the left, form on the right).
                // Phones get just the form panel, centered — the huge left
                // panel doesn't fit a phone screen, so it's dropped there.
                final isWide = constraints.maxWidth > 700;

                if (isWide) {
                  return Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Image.asset(
                            kLogoAsset,
                            width: 260,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(child: _LoginFormPanel()),
                      ),
                    ],
                  );
                }

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: _LoginFormPanel(),
                  ),
                );
              },
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () {
                  // Login is reached via pushNamed('/login') from the
                  // landing page's header, so there's normally a page to
                  // pop back to. The pushReplacementNamed fallback only
                  // matters if login is ever opened as the very first
                  // screen (e.g. during testing) with nothing to pop.
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacementNamed('/');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginFormPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 340),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset(
              kLogoAsset,
              height: 80,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'For Manager',
            style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          ),
          const SizedBox(height: 24),
          LoginFormWidget(
  onLoginSuccess: () {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;

    if (user == null) {
      return;
    }

    if (user.isOwner) {
      Navigator.of(context).pushReplacementNamed('/shops');
    } else {
      Navigator.of(context).pushReplacementNamed('/catalog');
    }
  },
),
        ],
      ),
    );
  }
}
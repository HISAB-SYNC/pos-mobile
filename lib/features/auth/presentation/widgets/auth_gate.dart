import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../../../landing/presentation/pages/landing_page.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../../core/theme/app_colors.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final auth = context.read<AuthProvider>();
    final shop = context.read<ShopProvider>();

    final isAuthenticated = await auth.initAuth();
    if (isAuthenticated) {
      await shop.initShop();
      final user = auth.currentUser;
      final token = auth.token;
      if (user?.isOwner == true && token != null) {
        if (shop.shops.isEmpty) {
          shop.loadShops(token);
        }
      } else if (user?.shopId != null && user!.shopId!.isNotEmpty) {
        shop.setShopForStaff(shopId: user.shopId!);
      }
    }

    if (mounted) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/andalus11.png',
                width: 90,
                height: 90,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.storefront,
                  size: 60,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Andalus HISAB-SYNC',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      return const DashboardPage();
    }

    return const LandingPage();
  }
}

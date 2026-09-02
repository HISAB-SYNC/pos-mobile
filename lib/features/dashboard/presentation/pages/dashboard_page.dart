import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../../shop/provider/shop_provider.dart';
import '../widgets/app_header.dart';
import '../widgets/owner_dashboard_view.dart';
import '../widgets/admin_dashboard_view.dart';
import '../widgets/sales_dashboard_view.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initShopContext();
    });
  }

  void _initShopContext() {
    final auth = context.read<AuthProvider>();
    final shopProvider = context.read<ShopProvider>();
    final user = auth.currentUser;
    final token = auth.token;

    if (user == null) return;

    if (user.isOwner && token != null && shopProvider.shops.isEmpty) {
      shopProvider.loadShops(token);
    } else if (!user.isOwner && user.shopId != null && shopProvider.selectedShop == null) {
      shopProvider.setShopForStaff(
        shopId: user.shopId!,
        name: 'SuperMart Store',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const AppHeader(title: 'Dashboard'),
      body: SafeArea(
        child: _buildRoleDashboard(user),
      ),
    );
  }

  Widget _buildRoleDashboard(dynamic user) {
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (user.isOwner) {
      return const OwnerDashboardView();
    } else if (user.isAdmin) {
      return const AdminDashboardView();
    } else {
      return const SalesDashboardView();
    }
  }
}

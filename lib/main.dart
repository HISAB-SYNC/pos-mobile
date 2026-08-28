import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'features/landing/presentation/pages/landing_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/product/provider/product_provider.dart';
import 'features/product/presentation/pages/products_list_page.dart';
import 'features/reports/provider/reports_provider.dart';
import 'features/reports/presentation/pages/reports_page.dart';
import 'features/orders/provider/orders_provider.dart';
import 'features/orders/presentation/pages/orders_page.dart';
import 'features/customer/provider/customer_provider.dart';
import 'features/customer/presentation/pages/customers_page.dart';
import 'features/expenses/provider/expenses_provider.dart';
import 'features/expenses/presentation/pages/expenses_page.dart';
import 'features/staff/provider/staff_provider.dart';
import 'features/staff/presentation/pages/staff_management_page.dart';
import 'features/settings/provider/settings_provider.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/category/provider/category_provider.dart';
import 'features/supplier/provider/supplier_provider.dart';
import 'features/supplier/presentation/pages/suppliers_list_page.dart';
import 'features/category/presentation/pages/category_management_page.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';
import 'features/cart/provider/cart_provider.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/sales/presentation/pages/checkout_page.dart';
import 'features/shop/provider/shop_provider.dart';
import 'features/shop/presentation/pages/shop_page.dart';
import 'features/dashboard/provider/dashboard_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiniShopApp());
}

class MiniShopApp extends StatelessWidget {
  const MiniShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ShopProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ReportsProvider()),
        ChangeNotifierProvider(create: (_) => OrdersProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ExpensesProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
      ],
      child: MaterialApp(
        title: 'Andalus POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthGate(),
          '/landing': (context) => const LandingPage(),
          '/login': (context) => const LoginPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/dashboard': (context) => const DashboardPage(),
          '/products': (context) => const ProductsListPage(),
          '/reports': (context) => const ReportsPage(),
          '/orders': (context) => const OrdersPage(),
          '/customers': (context) => const CustomersPage(),
          '/expenses': (context) => const ExpensesPage(),
          '/staff': (context) => const StaffManagementPage(),
          '/settings': (context) => const SettingsPage(),
          '/categories': (context) => const CategoryManagementPage(),
          '/suppliers': (context) => const SuppliersListPage(),
          '/catalog': (context) => const CatalogPage(),
          '/cart': (context) => const CartPage(),
          '/checkout': (context) => const CheckoutPage(),
          '/shops': (context) => const ShopPage(),
        },
      ),
    );
  }
}
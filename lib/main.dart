import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/auth/provider/auth_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
// import 'features/catalog/presentation/pages/catalog_placeholder_page.dart';
import 'features/landing/presentation/pages/landing_page.dart';
import 'features/catalog/presentation/pages/catalog_page.dart';
import 'features/cart/provider/cart_provider.dart';
import 'features/cart/presentation/pages/cart_page.dart';
import 'features/sales/presentation/pages/checkout_page.dart';
import 'features/shop/provider/shop_provider.dart';
import 'features/shop/presentation/pages/shop_page.dart';


void main() {
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
],
      child: MaterialApp(
        title: 'MiniShop',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const LandingPage(),
          '/login': (context) => const LoginPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          // '/catalog': (context) => const CatalogPlaceholderPage(),
          '/catalog': (context) => const CatalogPage(),
          '/cart': (context) => const CartPage(),
          '/checkout': (context) => const CheckoutPage(),
          '/shops': (context) => const ShopPage(),
        },
      ),
    );
  }
}
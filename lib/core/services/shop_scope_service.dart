import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/cart/provider/cart_provider.dart';
import '../../features/category/provider/category_provider.dart';
import '../../features/customer/provider/customer_provider.dart';
import '../../features/dashboard/provider/dashboard_provider.dart';
import '../../features/expenses/provider/expenses_provider.dart';
import '../../features/orders/provider/orders_provider.dart';
import '../../features/product/provider/product_provider.dart';
import '../../features/reports/provider/reports_provider.dart';
import '../../features/shop/models/shop.dart';
import '../../features/shop/provider/shop_provider.dart';
import '../../features/staff/provider/staff_provider.dart';
import '../../features/supplier/provider/supplier_provider.dart';

class ShopScopeService {
  /// Switches the active shop and synchronizes all shop-scoped providers across the entire app
  static void switchShop(BuildContext context, Shop shop) {
    final shopProvider = context.read<ShopProvider>();
    final authProvider = context.read<AuthProvider>();
    final token = authProvider.token;
    final user = authProvider.currentUser;
    final isSales = user?.isSales == true;

    // 1. Update active shop in ShopProvider and persist to SharedPreferences
    shopProvider.selectShop(shop);

    // 2. Clear stale cart from previous shop
    context.read<CartProvider>().clearCart();

    // 3. Immediately re-fetch all shop-scoped data for the new shop
    final shopId = shop.id;
    if (token != null && token.isNotEmpty && shopId.isNotEmpty) {
      // Dashboard aggregates (Sales, Low Stock, Debts)
      context.read<DashboardProvider>().loadDashboardMetrics(
            shopId: shopId,
            token: token,
            isSalesRole: isSales,
          );

      // Orders & Sales
      context.read<OrdersProvider>().loadOrders(shopId: shopId, token: token);

      // Products Catalog & Inventory
      context.read<ProductProvider>().loadProducts(shopId: shopId, token: token);

      // Customers & Debts
      context.read<CustomerProvider>().loadCustomers(shopId: shopId, token: token);

      // Reports & Analytics
      context.read<ReportsProvider>().loadReports(shopId: shopId, token: token);

      // Categories
      context.read<CategoryProvider>().loadCategories(shopId: shopId, token: token);

      // Suppliers
      context.read<SupplierProvider>().loadSuppliers(shopId: shopId, token: token);

      // In-app Expenses
      context.read<ExpensesProvider>().loadExpenses(shopId: shopId, token: token);

      // Staff Directory
      context.read<StaffProvider>().loadStaff(shopId: shopId, token: token);
    }
  }
}

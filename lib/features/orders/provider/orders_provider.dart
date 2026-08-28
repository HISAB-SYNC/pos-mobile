import 'package:flutter/foundation.dart';
import '../data/orders_repository.dart';
import '../models/order_model.dart';
import '../models/sale_model.dart';

class OrdersProvider extends ChangeNotifier {
  final OrdersRepository _repository = OrdersRepository();

  OrderSummary _summary = const OrderSummary();
  List<ShopOrder> _orders = [];
  List<Sale> _sales = [];
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  bool _isLoading = false;
  String? _errorMessage;

  OrderSummary get summary => _summary;
  List<ShopOrder> get orders {
    var list = _orders;
    if (_selectedStatusFilter != 'All') {
      list = list.where((o) => o.status.toLowerCase() == _selectedStatusFilter.toLowerCase()).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) =>
          o.productName.toLowerCase().contains(q) ||
          o.orderId.toLowerCase().contains(q) ||
          o.productId.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  List<Sale> get sales => _sales;
  String get searchQuery => _searchQuery;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders({required String shopId, String? token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _summary = await _repository.getOrderSummary(shopId: shopId, token: token);
    _orders = await _repository.getOrders(shopId: shopId, token: token);

    final salesRes = await _repository.getSales(shopId: shopId, token: token);
    if (salesRes['success'] == true && salesRes['data'] is List<Sale>) {
      _sales = salesRes['data'] as List<Sale>;
    }

    _isLoading = false;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setStatusFilter(String status) {
    _selectedStatusFilter = status;
    notifyListeners();
  }

  /// Create a POS sale via POST /shops/:shopId/sales
  Future<Map<String, dynamic>> processSale({
    required String shopId,
    required String token,
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0.0,
    String paymentMethod = 'CASH',
    bool isCredit = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.createSale(
      shopId: shopId,
      token: token,
      customerId: customerId,
      items: items,
      discountAmount: discountAmount,
      paymentMethod: paymentMethod,
      isCredit: isCredit,
    );

    _isLoading = false;

    if (result['success'] == true && result['data'] is Sale) {
      final createdSale = result['data'] as Sale;
      _sales.insert(0, createdSale);

      final firstItemName = createdSale.items.isNotEmpty ? createdSale.items.first.name : 'Sale Item';
      final totalItemsCount = createdSale.items.fold<int>(0, (sum, i) => sum + i.quantity);

      _orders.insert(
        0,
        ShopOrder(
          id: createdSale.id,
          orderId: createdSale.id.length > 8 ? createdSale.id.substring(0, 8) : createdSale.id,
          productName: createdSale.items.length > 1 ? '$firstItemName +${createdSale.items.length - 1} items' : firstItemName,
          productId: createdSale.items.isNotEmpty ? createdSale.items.first.productId : '',
          category: createdSale.paymentMethod,
          price: createdSale.totalAmount,
          quantity: totalItemsCount > 0 ? '$totalItemsCount Items' : '1 Item',
          expectedDelivery: createdSale.createdAt.isNotEmpty ? createdSale.createdAt.substring(0, 10) : 'Completed',
          status: createdSale.status == 'COMPLETED' ? 'Confirmed' : createdSale.status,
          createdAt: createdSale.createdAt,
        ),
      );

      _summary = OrderSummary(
        totalOrders: _orders.length,
        totalReceived: _orders.length,
        receivedRevenue: _summary.receivedRevenue + createdSale.totalAmount,
        totalReturned: 0,
        returnedCost: 0,
        onTheWay: 0,
        onTheWayCost: 0,
      );

      notifyListeners();
      return {'success': true, 'data': createdSale};
    } else {
      _errorMessage = result['error']?.toString() ?? 'Failed to complete sale';
      notifyListeners();
      return {'success': false, 'error': _errorMessage};
    }
  }

  Future<bool> createOrder({
    required String shopId,
    String? token,
    required ShopOrder order,
  }) async {
    _isLoading = true;
    notifyListeners();

    final created = await _repository.createOrder(
      shopId: shopId,
      token: token,
      order: order,
    );

    _orders.insert(0, created);
    _isLoading = false;
    notifyListeners();
    return true;
  }
}

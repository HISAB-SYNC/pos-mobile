import '../../../core/network/api_client.dart';
import '../models/order_model.dart';
import '../models/sale_model.dart';

class OrdersRepository {
  final ApiClient _client = ApiClient();

  /// POST /shops/:shopId/sales
  Future<Map<String, dynamic>> createSale({
    required String shopId,
    required String token,
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0.0,
    String paymentMethod = 'CASH',
    bool isCredit = false,
  }) async {
    try {
      final normalizedMethod = paymentMethod.toUpperCase().replaceAll(' ', '_');
      final validPaymentMethod = (normalizedMethod.contains('MOBILE') || normalizedMethod.contains('TELEBIRR'))
          ? 'MOBILE'
          : (normalizedMethod.contains('CARD') ? 'CARD' : 'CASH');

      final body = {
        if (customerId != null && customerId.isNotEmpty) 'customerId': customerId,
        'items': items,
        'discountAmount': discountAmount,
        'paymentMethod': validPaymentMethod,
        'isCredit': isCredit,
      };

      final response = await _client.post(
        '/shops/$shopId/sales',
        body,
        token: token,
      );

      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': Sale.fromJson(response['data'] as Map<String, dynamic>),
        };
      }

      return {
        'success': false,
        'error': response['error'] ?? 'Failed to complete sale',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// GET /shops/:shopId/sales
  Future<Map<String, dynamic>> getSales({
    required String shopId,
    String? token,
    String? startDate,
    String? endDate,
    String? customerId,
    String? paymentMethod,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (startDate != null && startDate.isNotEmpty) queryParams['startDate'] = startDate;
      if (endDate != null && endDate.isNotEmpty) queryParams['endDate'] = endDate;
      if (customerId != null && customerId.isNotEmpty) queryParams['customerId'] = customerId;
      if (paymentMethod != null && paymentMethod.isNotEmpty) queryParams['paymentMethod'] = paymentMethod;

      final uri = queryParams.isEmpty
          ? '/shops/$shopId/sales'
          : '/shops/$shopId/sales?${Uri(queryParameters: queryParams).query}';

      final response = await _client.get(uri, token: token);
      if (response['success'] == true && response['data'] is List) {
        final list = (response['data'] as List)
            .map((item) => Sale.fromJson(item as Map<String, dynamic>))
            .toList();
        return {'success': true, 'data': list};
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to load sales',
        'data': <Sale>[],
      };
    } catch (e) {
      return {'success': false, 'error': e.toString(), 'data': <Sale>[]};
    }
  }

  /// GET /shops/:shopId/sales/:id
  Future<Map<String, dynamic>> getSaleDetail({
    required String shopId,
    required String token,
    required String saleId,
  }) async {
    try {
      final response = await _client.get('/shops/$shopId/sales/$saleId', token: token);
      if (response['success'] == true && response['data'] != null) {
        return {
          'success': true,
          'data': Sale.fromJson(response['data'] as Map<String, dynamic>),
        };
      }
      return {
        'success': false,
        'error': response['error'] ?? 'Failed to load sale details',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<OrderSummary> getOrderSummary({required String shopId, String? token}) async {
    final salesResult = await getSales(shopId: shopId, token: token);
    final salesList = (salesResult['data'] is List<Sale>) ? (salesResult['data'] as List<Sale>) : <Sale>[];

    final total = salesList.length;
    final totalRev = salesList.fold<double>(0.0, (sum, s) => sum + s.totalAmount);

    return OrderSummary(
      totalOrders: total,
      totalReceived: total,
      receivedRevenue: totalRev,
      totalReturned: 0,
      returnedCost: 0,
      onTheWay: 0,
      onTheWayCost: 0,
    );
  }

  Future<List<ShopOrder>> getOrders({
    required String shopId,
    String? token,
    String? search,
    String? statusFilter,
  }) async {
    final salesResult = await getSales(shopId: shopId, token: token);
    final salesList = (salesResult['data'] is List<Sale>) ? (salesResult['data'] as List<Sale>) : <Sale>[];

    var list = salesList.map((s) {
      final firstItemName = s.items.isNotEmpty ? s.items.first.name : 'Sale Item';
      final totalItemsCount = s.items.fold<int>(0, (sum, i) => sum + i.quantity);
      return ShopOrder(
        id: s.id,
        orderId: s.id.length > 8 ? s.id.substring(0, 8) : s.id,
        productName: s.items.length > 1 ? '$firstItemName +${s.items.length - 1} items' : firstItemName,
        productId: s.items.isNotEmpty ? s.items.first.productId : '',
        category: s.paymentMethod,
        price: s.totalAmount,
        quantity: totalItemsCount > 0 ? '$totalItemsCount Items' : '1 Item',
        expectedDelivery: s.createdAt.isNotEmpty ? s.createdAt.substring(0, 10) : 'Completed',
        status: s.status == 'COMPLETED' ? 'Confirmed' : s.status,
        createdAt: s.createdAt,
      );
    }).toList();

    if (statusFilter != null && statusFilter != 'All' && statusFilter.isNotEmpty) {
      list = list.where((o) => o.status.toLowerCase() == statusFilter.toLowerCase()).toList();
    }

    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((o) =>
          o.productName.toLowerCase().contains(q) ||
          o.orderId.toLowerCase().contains(q) ||
          o.productId.toLowerCase().contains(q)).toList();
    }

    return list;
  }

  Future<ShopOrder> createOrder({
    required String shopId,
    String? token,
    required ShopOrder order,
  }) async {
    return order;
  }
}

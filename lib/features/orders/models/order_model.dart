class OrderSummary {
  final int totalOrders;
  final int totalReceived;
  final double receivedRevenue;
  final int totalReturned;
  final double returnedCost;
  final int onTheWay;
  final double onTheWayCost;

  const OrderSummary({
    this.totalOrders = 37,
    this.totalReceived = 32,
    this.receivedRevenue = 25000,
    this.totalReturned = 5,
    this.returnedCost = 2500,
    this.onTheWay = 12,
    this.onTheWayCost = 2356,
  });
}

class ShopOrder {
  final String id;
  final String orderId; // e.g. 7535
  final String productName;
  final String productId; // e.g. 23567
  final String category;
  final double price; // Price in ETB
  final String quantity; // e.g. '43 Packets' or '22 Packets'
  final String expectedDelivery; // e.g. '11/12/22'
  final String status; // 'Delayed' | 'Confirmed' | 'Returned' | 'Out for delivery'
  final bool notifyOnDelivery;
  final String createdAt;

  ShopOrder({
    required this.id,
    required this.orderId,
    required this.productName,
    this.productId = '',
    this.category = 'General',
    required this.price,
    required this.quantity,
    required this.expectedDelivery,
    required this.status,
    this.notifyOnDelivery = true,
    this.createdAt = '',
  });

  bool get isDelayed => status.toLowerCase() == 'delayed';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isReturned => status.toLowerCase() == 'returned';
  bool get isOutForDelivery => status.toLowerCase() == 'out for delivery';
  String get formattedDate => expectedDelivery.isNotEmpty ? expectedDelivery : (createdAt.isNotEmpty ? createdAt : 'Today');
}

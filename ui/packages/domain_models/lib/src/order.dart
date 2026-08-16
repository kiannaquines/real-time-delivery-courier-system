import 'enums.dart';

class OrderItem {
  final String id;
  final String menuItemId;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double subtotal;
  final String? specialInstructions;

  const OrderItem({
    required this.id,
    required this.menuItemId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      menuItemId: json['menu_item_id'] as String,
      itemName: json['item_name'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
      specialInstructions: json['special_instructions'] as String?,
    );
  }
}

class Payment {
  final String id;
  final String method;
  final double amount;
  final PaymentStatus status;
  final DateTime? collectedAt;

  const Payment({
    required this.id,
    this.method = 'cash_on_delivery',
    required this.amount,
    required this.status,
    this.collectedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      method: (json['method'] as String?) ?? 'cash_on_delivery',
      amount: (json['amount'] as num).toDouble(),
      status: PaymentStatus.fromString((json['status'] as String?) ?? 'unpaid'),
      collectedAt: json['collected_at'] != null ? DateTime.tryParse(json['collected_at'] as String) : null,
    );
  }
}

class DeliverySummary {
  final String id;
  final String orderId;
  final String? riderId;
  final String? riderName;
  final String? riderPhone;
  final OrderStatus status;
  final DateTime? pickupTime;
  final DateTime? deliveredTime;
  final double? lastLatitude;
  final double? lastLongitude;
  final DateTime? lastLocationTime;

  const DeliverySummary({
    required this.id,
    required this.orderId,
    this.riderId,
    this.riderName,
    this.riderPhone,
    required this.status,
    this.pickupTime,
    this.deliveredTime,
    this.lastLatitude,
    this.lastLongitude,
    this.lastLocationTime,
  });

  factory DeliverySummary.fromJson(Map<String, dynamic> json) {
    return DeliverySummary(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      riderId: json['rider_id'] as String?,
      riderName: json['rider_name'] as String?,
      riderPhone: json['rider_phone'] as String?,
      status: OrderStatus.fromString((json['status'] as String?) ?? 'pending'),
      pickupTime: json['pickup_time'] != null ? DateTime.tryParse(json['pickup_time'] as String) : null,
      deliveredTime: json['delivered_time'] != null ? DateTime.tryParse(json['delivered_time'] as String) : null,
      lastLatitude: json['last_latitude'] != null ? (json['last_latitude'] as num).toDouble() : null,
      lastLongitude: json['last_longitude'] != null ? (json['last_longitude'] as num).toDouble() : null,
      lastLocationTime: json['last_location_time'] != null ? DateTime.tryParse(json['last_location_time'] as String) : null,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String storeId;
  final String? storeName;
  final OrderStatus status;
  final double subtotal;
  final double deliveryFee;
  final double totalAmount;
  final PaymentStatus paymentStatus;
  final String deliveryAddress;
  final double deliveryLatitude;
  final double deliveryLongitude;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    required this.storeId,
    this.storeName,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.totalAmount,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.deliveryLatitude,
    required this.deliveryLongitude,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      storeId: json['store_id'] as String,
      storeName: json['store_name'] as String?,
      status: OrderStatus.fromString((json['status'] as String?) ?? 'pending'),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentStatus: PaymentStatus.fromString((json['payment_status'] as String?) ?? 'unpaid'),
      deliveryAddress: json['delivery_address'] as String,
      deliveryLatitude: (json['delivery_latitude'] as num).toDouble(),
      deliveryLongitude: (json['delivery_longitude'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class OrderDetail {
  final Order order;
  final List<OrderItem> items;
  final Payment? payment;
  final DeliverySummary? delivery;

  const OrderDetail({
    required this.order,
    this.items = const [],
    this.payment,
    this.delivery,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      order: Order.fromJson(json['order'] as Map<String, dynamic>),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((i) => OrderItem.fromJson(i as Map<String, dynamic>))
          .toList(),
      payment: json['payment'] != null ? Payment.fromJson(json['payment'] as Map<String, dynamic>) : null,
      delivery: json['delivery'] != null ? DeliverySummary.fromJson(json['delivery'] as Map<String, dynamic>) : null,
    );
  }
}

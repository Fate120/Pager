import 'product.dart';

class CartItem {
  final Product product;
  int quantity;
  String notes;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.notes = '',
  });

  int get subtotal => product.price * quantity;

  Map<String, dynamic> toJson() => {
    'id': product.id,
    'name': product.name,
    'price': product.price,
    'quantity': quantity,
    'notes': notes,
  };
}

class OrderItem {
  final int id;
  final String orderId;
  final int? productId;
  final String itemName;
  final int unitPrice;
  final int quantity;
  final int subtotal;
  final String? notes;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
    orderId: json['orderId'] ?? json['order_id'] ?? '',
    productId: json['productId'] ?? json['product_id'],
    itemName: json['itemName'] ?? json['item_name'] ?? json['name'] ?? '',
    unitPrice: json['unitPrice'] ?? json['unit_price'] ?? json['price'] ?? 0,
    quantity: json['quantity'] ?? 1,
    subtotal: json['subtotal'] ?? ((json['unitPrice'] ?? json['price'] ?? 0) * (json['quantity'] ?? 1)),
    notes: json['notes'],
  );
}

class OrderModel {
  final String id;
  final int orderNo;
  final String queueNumber;
  final String status; // preparing, ready, completed
  final String orderType; // dine_in, take_away
  final String? tableNo;
  final String customerName;
  final String paymentMethod;
  final int cashPaid;
  final int totalAmount;
  final String token;
  final String? ticketUrl;
  final int callCount;
  final DateTime createdAt;
  final List<OrderItem> items;

  OrderModel({
    required this.id,
    required this.orderNo,
    required this.queueNumber,
    required this.status,
    required this.orderType,
    this.tableNo,
    required this.customerName,
    required this.paymentMethod,
    required this.cashPaid,
    required this.totalAmount,
    required this.token,
    this.ticketUrl,
    this.callCount = 0,
    required this.createdAt,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<OrderItem> parsedItems = rawItems.map((i) => OrderItem.fromJson(i)).toList();

    return OrderModel(
      id: json['id'] ?? json['orderId'] ?? '',
      orderNo: json['orderNo'] ?? json['order_no'] ?? 0,
      queueNumber: json['queueNumber'] ?? json['queue_number'] ?? '',
      status: json['status'] ?? 'preparing',
      orderType: json['orderType'] ?? json['order_type'] ?? 'dine_in',
      tableNo: json['tableNo'] ?? json['table_no'],
      customerName: json['customerName'] ?? json['customer_name'] ?? 'Pelanggan',
      paymentMethod: json['paymentMethod'] ?? json['payment_method'] ?? 'cash',
      cashPaid: json['cashPaid'] ?? json['cash_paid'] ?? 0,
      totalAmount: json['totalAmount'] ?? json['total_amount'] ?? 0,
      token: json['token'] ?? json['ticketToken'] ?? '',
      ticketUrl: json['ticketUrl'],
      callCount: json['callCount'] ?? json['call_count'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: parsedItems,
    );
  }
}

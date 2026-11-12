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
    'productId': product.id,
    'productName': product.name,
    'itemName': product.name,
    'name': product.name,
    'price': product.price,
    'unitPrice': product.price,
    'quantity': quantity,
    'subtotal': subtotal,
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

  String get name => itemName;

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
  final String orderNo;
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
      id: (json['id'] ?? json['orderId'] ?? json['ticketId'] ?? '').toString(),
      orderNo: (json['orderNo'] ?? json['order_no'] ?? '').toString(),
      queueNumber: (json['queueNumber'] ?? json['queue_number'] ?? '').toString(),
      status: (json['status'] ?? 'preparing').toString(),
      orderType: (json['orderType'] ?? json['order_type'] ?? 'dine_in').toString(),
      tableNo: json['tableNo']?.toString(),
      customerName: (json['customerName'] ?? json['customer_name'] ?? 'Pelanggan').toString(),
      paymentMethod: (json['paymentMethod'] ?? json['payment_method'] ?? 'cash').toString(),
      cashPaid: json['cashPaid'] is int ? json['cashPaid'] : (int.tryParse(json['cashPaid']?.toString() ?? '') ?? 0),
      totalAmount: json['totalAmount'] is int ? json['totalAmount'] : (int.tryParse(json['totalAmount']?.toString() ?? '') ?? 0),
      token: (json['token'] ?? json['ticketToken'] ?? '').toString(),
      ticketUrl: json['ticketUrl']?.toString(),
      callCount: json['callCount'] is int ? json['callCount'] : (int.tryParse(json['callCount']?.toString() ?? '') ?? 0),
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      items: parsedItems,
    );
  }
}

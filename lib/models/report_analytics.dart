class DailySummary {
  final int totalRevenue;
  final int totalOrders;
  final int averageOrderValue;
  final int cashRevenue;
  final int qrisRevenue;

  DailySummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    this.cashRevenue = 0,
    this.qrisRevenue = 0,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
    totalRevenue: json['totalRevenue'] ?? json['total_revenue'] ?? 0,
    totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
    averageOrderValue: json['averageOrderValue'] ?? json['average_order_value'] ?? 0,
    cashRevenue: json['cashRevenue'] ?? json['cash_revenue'] ?? 0,
    qrisRevenue: json['qrisRevenue'] ?? json['qris_revenue'] ?? 0,
  );
}

class RevenueTrendPoint {
  final String date; // YYYY-MM-DD or label
  final String label;
  final int revenue;
  final int orders;

  RevenueTrendPoint({
    required this.date,
    this.label = '',
    required this.revenue,
    required this.orders,
  });

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) => RevenueTrendPoint(
    date: json['date'] ?? '',
    label: (json['label'] ?? json['date'] ?? '').toString(),
    revenue: json['revenue'] ?? 0,
    orders: json['orders'] ?? 0,
  );
}

class HourlySalesPoint {
  final int hour; // 0-23
  final int revenue;
  final int orders;

  HourlySalesPoint({
    required this.hour,
    required this.revenue,
    required this.orders,
  });

  factory HourlySalesPoint.fromJson(Map<String, dynamic> json) => HourlySalesPoint(
    hour: json['hour'] ?? 0,
    revenue: json['revenue'] ?? 0,
    orders: json['orders'] ?? 0,
  );
}

class TopProductItem {
  final int productId;
  final String productName;
  final String? imageUrl;
  final int totalQuantity;
  final int totalRevenue;

  TopProductItem({
    this.productId = 0,
    required this.productName,
    this.imageUrl,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) => TopProductItem(
    productId: json['productId'] ?? json['product_id'] ?? 0,
    productName: json['productName'] ?? json['item_name'] ?? json['name'] ?? '',
    imageUrl: json['imageUrl'] ?? json['image_url'],
    totalQuantity: json['totalQuantity'] ?? json['total_quantity'] ?? json['quantity'] ?? 0,
    totalRevenue: json['totalRevenue'] ?? json['total_revenue'] ?? json['revenue'] ?? 0,
  );
}

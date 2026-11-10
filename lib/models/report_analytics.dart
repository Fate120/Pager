class DailySummary {
  final int totalRevenue;
  final int totalOrders;
  final int averageOrderValue;

  DailySummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) => DailySummary(
    totalRevenue: json['totalRevenue'] ?? json['total_revenue'] ?? 0,
    totalOrders: json['totalOrders'] ?? json['total_orders'] ?? 0,
    averageOrderValue: json['averageOrderValue'] ?? json['average_order_value'] ?? 0,
  );
}

class RevenueTrendPoint {
  final String date; // YYYY-MM-DD
  final int revenue;
  final int orders;

  RevenueTrendPoint({
    required this.date,
    required this.revenue,
    required this.orders,
  });

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) => RevenueTrendPoint(
    date: json['date'] ?? '',
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
  final String productName;
  final int totalQuantity;
  final int totalRevenue;

  TopProductItem({
    required this.productName,
    required this.totalQuantity,
    required this.totalRevenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> json) => TopProductItem(
    productName: json['productName'] ?? json['item_name'] ?? json['name'] ?? '',
    totalQuantity: json['totalQuantity'] ?? json['total_quantity'] ?? json['quantity'] ?? 0,
    totalRevenue: json['totalRevenue'] ?? json['total_revenue'] ?? json['revenue'] ?? 0,
  );
}

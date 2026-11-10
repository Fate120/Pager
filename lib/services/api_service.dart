import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/store_profile.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/report_analytics.dart';
import 'storage_service.dart';

class ApiService {
  String get baseUrl => StorageService.getBaseUrl();

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. Store Config
  Future<StoreProfile?> fetchStoreConfig() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/config'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return StoreProfile.fromJson(data);
      }
    } catch (e) {
      print('fetchStoreConfig error: $e');
    }
    return null;
  }

  Future<bool> saveStoreConfig(StoreProfile profile) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/config'),
        headers: _headers,
        body: jsonEncode(profile.toJson()),
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      print('saveStoreConfig error: $e');
      return false;
    }
  }

  // 2. Categories & Products
  Future<List<Category>> fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/categories'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((c) => Category.fromJson(c)).toList();
      }
    } catch (e) {
      print('fetchCategories error: $e');
    }
    return [];
  }

  Future<List<Product>> fetchProducts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/products'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((p) => Product.fromJson(p)).toList();
      }
    } catch (e) {
      print('fetchProducts error: $e');
    }
    return [];
  }

  Future<Product?> addProduct(Product product) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/products'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return Product.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('addProduct error: $e');
    }
    return null;
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/api/v1/products/${product.id}'),
        headers: _headers,
        body: jsonEncode(product.toJson()),
      );
      return res.statusCode == 200;
    } catch (e) {
      print('updateProduct error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(int productId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/api/v1/products/$productId'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('deleteProduct error: $e');
      return false;
    }
  }

  // 3. POS & Queue
  Future<Map<String, dynamic>?> createOrder({
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
    required int cashPaid,
    String customerName = 'Pelanggan',
    String orderType = 'dine_in',
    String? tableNo,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/pos/orders'),
        headers: _headers,
        body: jsonEncode({
          'paymentMethod': paymentMethod,
          'items': items,
          'cashPaid': cashPaid,
          'customerName': customerName,
          'orderType': orderType,
          'tableNo': tableNo,
        }),
      );
      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('createOrder error: $e');
    }
    return null;
  }

  Future<List<OrderModel>> fetchActiveQueue() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/queue/active'), headers: _headers);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['activeTickets'] ?? data['tickets'] ?? []) as List;
        return list.map((t) => OrderModel.fromJson(t)).toList();
      }
    } catch (e) {
      print('fetchActiveQueue error: $e');
    }
    return [];
  }

  Future<bool> callOrder(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/queue/$orderId/call'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('callOrder error: $e');
      return false;
    }
  }

  Future<bool> completeOrder(String orderId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/v1/queue/$orderId/complete'),
        headers: _headers,
      );
      return res.statusCode == 200;
    } catch (e) {
      print('completeOrder error: $e');
      return false;
    }
  }

  // 4. Reports & Analytics
  Future<DailySummary?> fetchSummary({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final res = await http.get(Uri.parse('$baseUrl/api/v1/reports/summary$query'), headers: _headers);
      if (res.statusCode == 200) {
        return DailySummary.fromJson(jsonDecode(res.body));
      }
    } catch (e) {
      print('fetchSummary error: $e');
    }
    return null;
  }

  Future<List<RevenueTrendPoint>> fetchRevenueTrend({int days = 7}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/reports/trend?days=$days'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => RevenueTrendPoint.fromJson(i)).toList();
      }
    } catch (e) {
      print('fetchRevenueTrend error: $e');
    }
    return [];
  }

  Future<List<HourlySalesPoint>> fetchHourlySales({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final res = await http.get(Uri.parse('$baseUrl/api/v1/reports/hourly$query'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => HourlySalesPoint.fromJson(i)).toList();
      }
    } catch (e) {
      print('fetchHourlySales error: $e');
    }
    return [];
  }

  Future<List<TopProductItem>> fetchTopProducts({int limit = 5}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/v1/reports/top-products?limit=$limit'), headers: _headers);
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((i) => TopProductItem.fromJson(i)).toList();
      }
    } catch (e) {
      print('fetchTopProducts error: $e');
    }
    return [];
  }

  Future<List<OrderModel>> fetchTransactionHistory({int page = 1, int limit = 30, String? date}) async {
    try {
      final dateParam = date != null ? '&date=$date' : '';
      final res = await http.get(
        Uri.parse('$baseUrl/api/v1/reports/transactions?page=$page&limit=$limit$dateParam'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['transactions'] ?? data['orders'] ?? data) as List;
        return list.map((o) => OrderModel.fromJson(o)).toList();
      }
    } catch (e) {
      print('fetchTransactionHistory error: $e');
    }
    return [];
  }
}

import 'package:flutter/foundation.dart';
import '../models/store_profile.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/report_analytics.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/thermal_printer_service.dart';

class StoreProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // Profile & Onboarding
  StoreProfile _profile = StoreProfile(
    outletName: 'Kedai Kopi Aksiva',
    address: '',
    phoneNumber: '',
    receiptCustomText: '',
  );
  bool _hasOnboarded = false;

  // Catalog
  List<Category> _categories = [];
  List<Product> _products = [];
  int? _selectedCategoryId;
  bool _isLoadingCatalog = false;

  // Cart
  final List<CartItem> _cart = [];
  String _orderType = 'dine_in'; // dine_in, take_away
  String? _tableNo;
  String _customerName = 'Pelanggan';

  // Queue
  List<OrderModel> _activeQueue = [];

  // Reports
  DailySummary? _dailySummary;
  List<RevenueTrendPoint> _revenueTrends = [];
  List<HourlySalesPoint> _hourlySales = [];
  List<TopProductItem> _topProducts = [];
  List<OrderModel> _transactions = [];
  bool _isLoadingReports = false;

  // Printer
  bool _isPrinterConnected = false;
  String? _connectedPrinterName;

  // Getters
  StoreProfile get profile => _profile;
  bool get hasOnboarded => _hasOnboarded;
  List<Category> get categories => _categories;
  List<Product> get products {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }
  List<Product> get allProducts => _products;
  int? get selectedCategoryId => _selectedCategoryId;
  bool get isLoadingCatalog => _isLoadingCatalog;
  List<CartItem> get cart => _cart;
  String get orderType => _orderType;
  String? get tableNo => _tableNo;
  String get customerName => _customerName;
  int get cartTotal => _cart.fold(0, (sum, item) => sum + item.subtotal);
  int get cartItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  List<OrderModel> get activeQueue => _activeQueue;
  DailySummary? get dailySummary => _dailySummary;
  List<RevenueTrendPoint> get revenueTrends => _revenueTrends;
  List<HourlySalesPoint> get hourlySales => _hourlySales;
  List<TopProductItem> get topProducts => _topProducts;
  List<OrderModel> get transactions => _transactions;
  bool get isLoadingReports => _isLoadingReports;
  bool get isPrinterConnected => _isPrinterConnected;
  String? get connectedPrinterName => _connectedPrinterName;

  // Init
  Future<void> init() async {
    final savedProfile = StorageService.getStoreProfile();
    if (savedProfile != null) {
      _profile = savedProfile;
      _hasOnboarded = true;
    } else {
      _hasOnboarded = false;
    }

    _connectedPrinterName = StorageService.getPrinterName();
    checkPrinterStatus();

    await loadCatalog();
    notifyListeners();
  }

  // 1. Profile Actions
  Future<void> updateProfile(StoreProfile newProfile) async {
    _profile = newProfile;
    _hasOnboarded = true;
    await StorageService.saveStoreProfile(newProfile);
    await _api.saveStoreConfig(newProfile);
    notifyListeners();
  }

  // 2. Catalog Actions
  Future<void> loadCatalog() async {
    _isLoadingCatalog = true;
    notifyListeners();

    _categories = await _api.fetchCategories();
    _products = await _api.fetchProducts();

    // Fallback seed catalog if backend database is fresh
    if (_products.isEmpty) {
      _seedDefaultCatalog();
    }

    _isLoadingCatalog = false;
    notifyListeners();
  }

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> toggleProductAvailability(Product product) async {
    final updated = product.copyWith(isAvailable: !product.isAvailable);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = updated;
      notifyListeners();
      await _api.updateProduct(updated);
    }
  }

  Future<void> addProduct(Product product) async {
    final created = await _api.addProduct(product);
    if (created != null) {
      _products.add(created);
    } else {
      _products.add(product.copyWith(id: DateTime.now().millisecondsSinceEpoch));
    }
    notifyListeners();
  }

  Future<void> editProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      notifyListeners();
      await _api.updateProduct(product);
    }
  }

  Future<void> deleteProduct(int productId) async {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
    await _api.deleteProduct(productId);
  }

  // 3. Cart Actions
  void addToCart(Product product, {String notes = ''}) {
    if (!product.isAvailable) return;
    final index = _cart.indexWhere((c) => c.product.id == product.id && c.notes == notes);
    if (index != -1) {
      _cart[index].quantity += 1;
    } else {
      _cart.add(CartItem(product: product, quantity: 1, notes: notes));
    }
    notifyListeners();
  }

  void updateQuantity(CartItem item, int delta) {
    item.quantity += delta;
    if (item.quantity <= 0) {
      _cart.remove(item);
    }
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _tableNo = null;
    notifyListeners();
  }

  void setOrderType(String type) {
    _orderType = type;
    notifyListeners();
  }

  void setTableNo(String? table) {
    _tableNo = table;
    notifyListeners();
  }

  void setCustomerName(String name) {
    _customerName = name;
    notifyListeners();
  }

  // 4. POS Checkout
  Future<OrderModel?> checkout({
    required String paymentMethod,
    required int cashPaid,
  }) async {
    if (_cart.isEmpty) return null;

    final items = _cart.map((c) => c.toJson()).toList();
    final res = await _api.createOrder(
      paymentMethod: paymentMethod,
      items: items,
      cashPaid: cashPaid,
      customerName: _customerName,
      orderType: _orderType,
      tableNo: _tableNo,
    );

    if (res != null) {
      final orderData = res['ticket'] ?? res['order'] ?? res;
      final newOrder = OrderModel.fromJson(orderData);
      clearCart();
      loadActiveQueue();
      return newOrder;
    }
    return null;
  }

  // 5. Queue Actions
  Future<void> loadActiveQueue() async {
    _activeQueue = await _api.fetchActiveQueue();
    notifyListeners();
  }

  Future<bool> callQueue(String orderId) async {
    final ok = await _api.callOrder(orderId);
    if (ok) await loadActiveQueue();
    return ok;
  }

  Future<bool> completeQueue(String orderId) async {
    final ok = await _api.completeOrder(orderId);
    if (ok) await loadActiveQueue();
    return ok;
  }

  // 6. Reports Actions
  Future<void> loadReports({int trendDays = 7, String? date}) async {
    _isLoadingReports = true;
    notifyListeners();

    _dailySummary = await _api.fetchSummary(date: date);
    _revenueTrends = await _api.fetchRevenueTrend(days: trendDays);
    _hourlySales = await _api.fetchHourlySales(date: date);
    _topProducts = await _api.fetchTopProducts(limit: 5);
    _transactions = await _api.fetchTransactionHistory(date: date);

    _isLoadingReports = false;
    notifyListeners();
  }

  // 7. Thermal Printer Actions
  Future<void> checkPrinterStatus() async {
    _isPrinterConnected = await ThermalPrinterService.isConnected();
    notifyListeners();
  }

  Future<bool> printOrderReceipt(OrderModel order) async {
    return await ThermalPrinterService.printReceipt(
      order: order,
      storeProfile: _profile,
    );
  }

  // Seed default menu data
  void _seedDefaultCatalog() {
    _categories = [
      Category(id: 1, name: 'Kopi', emoji: '☕', sortOrder: 1),
      Category(id: 2, name: 'Non-Kopi', emoji: '🍵', sortOrder: 2),
      Category(id: 3, name: 'Makanan', emoji: '🍚', sortOrder: 3),
      Category(id: 4, name: 'Camilan', emoji: '🥐', sortOrder: 4),
    ];
    _products = [
      Product(id: 1, categoryId: 1, name: 'Americano', price: 15000, emoji: '☕'),
      Product(id: 2, categoryId: 1, name: 'Latte', price: 18000, emoji: '☕'),
      Product(id: 3, categoryId: 1, name: 'Cappuccino', price: 18000, emoji: '☕'),
      Product(id: 4, categoryId: 1, name: 'Kopi Susu Aren', price: 20000, emoji: '☕'),
      Product(id: 5, categoryId: 2, name: 'Matcha Latte', price: 22000, emoji: '🍵'),
      Product(id: 6, categoryId: 2, name: 'Ice Lemon Tea', price: 18000, emoji: '🍋'),
      Product(id: 7, categoryId: 3, name: 'Toast Coklat', price: 20000, emoji: '🍞'),
      Product(id: 8, categoryId: 3, name: 'Nasi Goreng', price: 25000, emoji: '🍚'),
      Product(id: 9, categoryId: 4, name: 'Croissant Butter', price: 15000, emoji: '🥐'),
      Product(id: 10, categoryId: 4, name: 'Donat Kampung', price: 12000, emoji: '🍩'),
    ];
  }
}

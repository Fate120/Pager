import 'package:flutter/foundation.dart' hide Category;
import '../models/store_profile.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/report_analytics.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/thermal_printer_service.dart';

class StoreProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  // Profile & Onboarding
  StoreProfile _profile = StoreProfile(
    outletName: 'Kedai Kopi Aksiva',
    address: 'Jl. Rinjani No. 12, Semarang',
    phoneNumber: '08562872671',
    receiptCustomText: 'Terima kasih atas kunjungan Anda!',
  );
  bool _hasOnboarded = false;
  bool _isInitialized = false;

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
  String _trendPeriod = 'daily';
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
  bool get isInitialized => _isInitialized;
  List<Category> get categories => _categories;
  List<Product> get products {
    if (_selectedCategoryId == null) return _products;
    return _products.where((p) => p.categoryId == _selectedCategoryId).toList();
  }
  List<Product> get filteredProducts => products;
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
  String get trendPeriod => _trendPeriod;
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
      final remoteConfig = await _api.fetchStoreConfig();
      if (remoteConfig != null && remoteConfig.outletName.isNotEmpty) {
        _profile = remoteConfig;
        _hasOnboarded = true;
        await StorageService.saveStoreProfile(remoteConfig);
      } else {
        _hasOnboarded = false;
      }
    }

    _connectedPrinterName = StorageService.getPrinterName();
    checkPrinterStatus();

    await loadCatalog();
    await loadActiveQueue();
    _isInitialized = true;
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

    final apiCategories = await _api.fetchCategories();
    final apiProducts = await _api.fetchProducts();

    if (apiCategories.isNotEmpty) {
      _categories = apiCategories;
    } else {
      _categories = StorageService.getCategories() ?? [];
    }

    if (apiProducts.isNotEmpty) {
      _products = apiProducts;
    } else {
      _products = StorageService.getProducts() ?? [];
    }

    // Remove legacy emoji-only products
    _products.removeWhere((p) => p.imageUrl == null || p.imageUrl!.trim().isEmpty);

    await StorageService.saveCategories(_categories);
    await StorageService.saveProducts(_products);

    _isLoadingCatalog = false;
    notifyListeners();
  }

  void selectCategory(int? id) {
    _selectedCategoryId = id;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final created = await _api.addCategory(Category(
      id: 0,
      name: trimmed,
      sortOrder: _categories.length + 1,
    ));
    final newCat = created ?? Category(
      id: DateTime.now().millisecondsSinceEpoch,
      name: trimmed,
      sortOrder: _categories.length + 1,
    );
    _categories.add(newCat);
    await StorageService.saveCategories(_categories);
    notifyListeners();
  }

  Future<void> editCategory(int id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _categories[idx] = _categories[idx].copyWith(name: trimmed);
      await StorageService.saveCategories(_categories);
      notifyListeners();
      await _api.updateCategory(_categories[idx]);
    }
  }

  Future<void> deleteCategory(int id, {bool deleteProductsUnderCategory = false}) async {
    _categories.removeWhere((c) => c.id == id);
    if (_selectedCategoryId == id) {
      _selectedCategoryId = null;
    }

    if (deleteProductsUnderCategory) {
      final toDelete = _products.where((p) => p.categoryId == id).toList();
      _products.removeWhere((p) => p.categoryId == id);
      for (final p in toDelete) {
        _api.deleteProduct(p.id);
      }
      await StorageService.saveProducts(_products);
    } else {
      bool productsChanged = false;
      for (int i = 0; i < _products.length; i++) {
        if (_products[i].categoryId == id) {
          _products[i] = _products[i].copyWith(clearCategoryId: true);
          productsChanged = true;
          _api.updateProduct(_products[i]);
        }
      }
      if (productsChanged) {
        await StorageService.saveProducts(_products);
      }
    }

    await StorageService.saveCategories(_categories);
    notifyListeners();
    await _api.deleteCategory(id);
  }

  Future<void> toggleProductAvailability(Product product) async {
    final updated = product.copyWith(isAvailable: !product.isAvailable);
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = updated;
      await StorageService.saveProducts(_products);
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
    await StorageService.saveProducts(_products);
    notifyListeners();
  }

  Future<void> editProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx != -1) {
      _products[idx] = product;
      await StorageService.saveProducts(_products);
      notifyListeners();
      await _api.updateProduct(product);
    }
  }

  Future<void> deleteProduct(int productId) async {
    _products.removeWhere((p) => p.id == productId);
    await StorageService.saveProducts(_products);
    notifyListeners();
    await _api.deleteProduct(productId);
  }

  // 3. Cart Actions
  void addToCart(
    Product product, {
    String notes = '',
    List<ProductAddon> selectedAddOns = const [],
    int quantity = 1,
  }) {
    if (!product.isAvailable) return;

    final index = _cart.indexWhere((c) {
      if (c.product.id != product.id) return false;
      if (c.notes.trim() != notes.trim()) return false;
      if (c.selectedAddOns.length != selectedAddOns.length) return false;
      final existingIds = c.selectedAddOns.map((a) => a.id).toSet();
      final newIds = selectedAddOns.map((a) => a.id).toSet();
      return existingIds.containsAll(newIds);
    });

    if (index != -1) {
      _cart[index].quantity += quantity;
    } else {
      _cart.add(CartItem(
        product: product,
        quantity: quantity,
        notes: notes,
        selectedAddOns: List.from(selectedAddOns),
      ));
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
    if (_orderType == type) return;
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
    String? customerName,
  }) async {
    if (_cart.isEmpty) return null;

    final targetCustomerName = (customerName != null && customerName.trim().isNotEmpty)
        ? customerName.trim()
        : _customerName;

    final items = _cart.map((c) => c.toJson()).toList();
    final res = await _api.createOrder(
      paymentMethod: paymentMethod,
      items: items,
      cashPaid: cashPaid,
      customerName: targetCustomerName,
      orderType: _orderType,
      tableNo: _tableNo,
    );

    if (res != null) {
      final Map<String, dynamic> orderData = res['ticket'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(res['ticket'])
          : (res['order'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(res['order'])
              : Map<String, dynamic>.from(res));
      if (res['ticketUrl'] != null) {
        orderData['ticketUrl'] = res['ticketUrl'];
      }
      final newOrder = OrderModel.fromJson(orderData);
      clearCart();
      _customerName = '';
      _tableNo = null;
      loadActiveQueue();
      loadReports();
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
    if (ok) {
      await loadActiveQueue();
      await loadReports();
    }
    return ok;
  }

  // 6. Reports Actions
  Future<void> setTrendPeriod(String period) async {
    if (_trendPeriod == period) return;
    _trendPeriod = period;
    notifyListeners();
    _revenueTrends = await _api.fetchRevenueTrend(type: _trendPeriod);
    notifyListeners();
  }

  Future<void> loadReports({int trendDays = 7, String? date}) async {
    _isLoadingReports = true;
    notifyListeners();

    _dailySummary = await _api.fetchSummary(date: date);
    _revenueTrends = await _api.fetchRevenueTrend(type: _trendPeriod);
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

  // Seed default menu data without emojis
  void _seedDefaultCatalog() {
    _categories = [
      Category(id: 1, name: 'Kopi', sortOrder: 1),
      Category(id: 2, name: 'Non-Kopi', sortOrder: 2),
      Category(id: 3, name: 'Makanan', sortOrder: 3),
      Category(id: 4, name: 'Camilan', sortOrder: 4),
    ];
    _products = [];
  }
}

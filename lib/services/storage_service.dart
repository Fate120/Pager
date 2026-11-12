import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/store_profile.dart';
import '../config/app_theme.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Store Profile
  static Future<bool> saveStoreProfile(StoreProfile profile) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setString(
      AppConstants.keyStoreProfile,
      jsonEncode(profile.toJson()),
    );
  }

  static StoreProfile? getStoreProfile() {
    final raw = _prefs?.getString(AppConstants.keyStoreProfile);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      return StoreProfile.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  static bool hasCompletedOnboarding() {
    final profile = getStoreProfile();
    return profile != null && profile.outletName.isNotEmpty;
  }

  static bool isOnboarded() => hasCompletedOnboarding();

  // Base URL
  static Future<bool> saveBaseUrl(String url) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    return await prefs.setString(AppConstants.keyBaseUrl, url);
  }

  static String getBaseUrl() {
    return _prefs?.getString(AppConstants.keyBaseUrl) ?? AppConstants.defaultBaseUrl;
  }

  // Bluetooth Printer Settings
  static Future<bool> savePrinterSettings({
    required String macAddress,
    required String name,
    int paperSizeMm = 58,
  }) async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyPrinterAddress, macAddress);
    await prefs.setString(AppConstants.keyPrinterName, name);
    return await prefs.setInt(AppConstants.keyPaperSize, paperSizeMm);
  }

  static String? getPrinterAddress() => _prefs?.getString(AppConstants.keyPrinterAddress);
  static String? getPrinterName() => _prefs?.getString(AppConstants.keyPrinterName);
  static int getPaperSize() => _prefs?.getInt(AppConstants.keyPaperSize) ?? 58;
}

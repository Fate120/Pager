import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/store_provider.dart';
import 'screens/onboarding/profile_setup_screen.dart';
import 'screens/pos/pos_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => StoreProvider()..init()),
      ],
      child: const KasirApp(),
    ),
  );
}

class KasirApp extends StatelessWidget {
  const KasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aksiva Kasir POS & Pager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: Consumer<StoreProvider>(
        builder: (context, store, _) {
          if (!store.isInitialized) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundSand,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNavy),
              ),
            );
          }
          final isOnboarded = store.hasOnboarded || StorageService.isOnboarded();
          return isOnboarded ? const PosScreen() : const ProfileSetupScreen(isInitialSetup: true);
        },
      ),
    );
  }
}

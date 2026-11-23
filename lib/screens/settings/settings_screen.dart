import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/store_provider.dart';
import '../../services/storage_service.dart';
import '../onboarding/profile_setup_screen.dart';
import 'printer_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppTheme.primaryNavy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            title: 'Profil Kedai & Teks Struk',
            subtitle: '${provider.profile.outletName} • ${provider.profile.phoneNumber}',
            icon: Icons.store,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ProfileSetupScreen(isInitialSetup: false)),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'Printer Thermal Bluetooth',
            subtitle: provider.isPrinterConnected ? 'Terhubung' : 'Belum terhubung',
            icon: Icons.print,
            badgeColor: provider.isPrinterConnected ? AppTheme.successGreen : AppTheme.dangerRed,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrinterSettingsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _buildSettingCard(
            title: 'URL Server / Backend API',
            subtitle: StorageService.getBaseUrl(),
            icon: Icons.cloud,
            onTap: () => _editBackendUrlDialog(context),
          ),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'Aksiva Kasir & Digital Pager v1.0.0\nBuilt for Android Tablet & Smartphone',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? badgeColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderBlack, width: 2),
        boxShadow: AppTheme.brutalistShadow(offset: 2),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.accentYellow,
            border: Border.all(color: AppTheme.borderBlack, width: 1.5),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppTheme.primaryNavy),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: badgeColor != null
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
              )
            : const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _editBackendUrlDialog(BuildContext context) {
    final ctrl = TextEditingController(text: StorageService.getBaseUrl());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('URL Backend API (Railway / Local)'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://pager-production.up.railway.app',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newUrl = ctrl.text.trim();
              if (newUrl.isNotEmpty) {
                await StorageService.saveBaseUrl(newUrl);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL Backend berhasil diperbarui!')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

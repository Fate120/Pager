import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/store_profile.dart';
import '../../providers/store_provider.dart';
import '../pos/pos_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  final bool isInitialSetup;
  const ProfileSetupScreen({super.key, this.isInitialSetup = true});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final profile = context.read<StoreProvider>().profile;
    _nameController = TextEditingController(text: profile.outletName);
    _addressController = TextEditingController(text: profile.address);
    _phoneController = TextEditingController(text: profile.phoneNumber);
    _notesController = TextEditingController(text: profile.receiptCustomText);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final newProfile = StoreProfile(
      outletName: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      receiptCustomText: _notesController.text.trim(),
    );

    await context.read<StoreProvider>().updateProfile(newProfile);

    if (mounted) {
      if (widget.isInitialSetup) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PosScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profil kedai berhasil diperbarui!')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundSand,
      appBar: AppBar(
        title: Text(widget.isInitialSetup ? 'Setup Profil Kedai' : 'Pengaturan Struk & Kedai'),
        backgroundColor: AppTheme.primaryNavy,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderBlack, width: 2.5),
              boxShadow: AppTheme.brutalistShadow(offset: 6),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.accentYellow,
                          border: Border.all(color: AppTheme.borderBlack, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('☕', style: TextStyle(fontSize: 28)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informasi Struk',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.primaryNavy,
                              ),
                            ),
                            Text(
                              widget.isInitialSetup
                                  ? 'Isi profil usaha Anda agar struk kasir otomatis tercetak rapi.'
                                  : 'Ubah teks yang akan tercetak pada kop & footer struk thermal.',
                              style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderBlack, thickness: 1.5),
                  const SizedBox(height: 16),

                  // Nama Kedai
                  const Text('Nama Kedai / Usaha *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Kedai Kopi Aksiva',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.borderBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama kedai wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Alamat
                  const Text('Alamat Lengkap *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Jl. Rinjani No. 12, Semarang',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.borderBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat kedai wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Nomor Telepon / WA
                  const Text('Nomor WhatsApp / Telepon *', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Contoh: 08562872671',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.borderBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nomor telepon wajib diisi' : null,
                  ),
                  const SizedBox(height: 16),

                  // Pesan Tambahan Struk
                  const Text('Pesan Tambahan di Struk (Opsional)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Password WiFi: aksiva2026 | IG: @kedaiaksiva',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(color: AppTheme.borderBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppTheme.borderBlack, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      widget.isInitialSetup ? 'SIMPAN & MASUK KASIR ➔' : 'SIMPAN PERUBAHAN',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (widget.isInitialSetup) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final defaultProfile = StoreProfile(
                          outletName: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Kedai Kopi Aksiva',
                          address: _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Jl. Rinjani No. 12, Semarang',
                          phoneNumber: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : '08562872671',
                          receiptCustomText: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : 'Terima kasih atas kunjungan Anda!',
                        );
                        await context.read<StoreProvider>().updateProfile(defaultProfile);
                        if (mounted) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const PosScreen()),
                          );
                        }
                      },
                      child: const Text(
                        'Lewati & Masuk Menggunakan Data Bawaan ➔',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryNavy,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

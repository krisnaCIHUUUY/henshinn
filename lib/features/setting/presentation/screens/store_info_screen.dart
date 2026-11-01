import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:henshin/features/setting/domain/repositories/settings_repository.dart';
import 'package:henshin/injection_container.dart';

/// Info toko yang dicetak di header dan footer struk (PRD §2.6). Disimpan di
/// tabel `settings` yang sudah ada sejak langkah 2.
class StoreInfoScreen extends StatefulWidget {
  const StoreInfoScreen({super.key});

  @override
  State<StoreInfoScreen> createState() => _StoreInfoScreenState();
}

class _StoreInfoScreenState extends State<StoreInfoScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _message = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // try/catch, bukan hanya fold: kalau `sl<...>()` atau DB-nya melempar,
    // `_loading` harus tetap dimatikan — layar tidak boleh macet di spinner.
    try {
      final result = await sl<SettingsRepository>().getStoreInfo();
      if (!mounted) return;

      final info = result.getOrElse(() => const StoreInfo());
      _name.text = info.name;
      _address.text = info.address;
      _message.text = info.receiptMessage;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Gagal memuat info toko: $e';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      final result = await sl<SettingsRepository>().updateStoreInfo(
        name: _name.text,
        address: _address.text,
        receiptMessage: _message.text,
      );
      if (!mounted) return;
      setState(() => _saving = false);

      result.fold(
        (failure) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message))),
        (_) => Navigator.of(context).pop(true),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: const Text('Info Toko'),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _LoadError(message: _error!, onRetry: _load)
            : ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  _Field(
                    controller: _name,
                    label: 'Nama toko',
                    helper: 'Dicetak paling atas di struk',
                    capitalize: true,
                  ),
                  _Field(
                    controller: _address,
                    label: 'Alamat',
                    helper: 'Boleh dikosongkan',
                    maxLines: 2,
                    capitalize: true,
                  ),
                  _Field(
                    controller: _message,
                    label: 'Pesan penutup struk',
                    helper: 'Mis. "Terima kasih". Boleh dikosongkan',
                    maxLines: 2,
                    capitalize: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    height: AppSpacing.touchTargetMin,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.onSurface,
                        foregroundColor: AppColor.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdAll,
                        ),
                      ),
                      child: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.helper,
    this.maxLines = 1,
    this.capitalize = false,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final int maxLines;
  final bool capitalize;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        textCapitalization: capitalize
            ? TextCapitalization.words
            : TextCapitalization.none,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          border: OutlineInputBorder(borderRadius: AppRadius.mdAll),
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColor.error),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/core/widgets/app_badge.dart';
import 'package:henshin/core/widgets/app_card.dart';
import 'package:henshin/core/widgets/section_header.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/domain/repositories/settings_repository.dart';
import 'package:henshin/features/setting/presentation/backup_action.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/features/setting/presentation/restore_action.dart';
import 'package:henshin/features/setting/presentation/screens/store_info_screen.dart';
import 'package:henshin/features/setting/presentation/widgets/backup_reminder.dart';
import 'package:henshin/injection_container.dart';
import 'package:intl/intl.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _hasPin = false;
  StoreInfo _store = const StoreInfo();

  @override
  void initState() {
    super.initState();
    _loadPinStatus();
    _loadStoreInfo();
  }

  /// Gagal baca bukan masalah fatal di layar ini: barisnya cukup menampilkan
  /// "Belum diisi". Yang penting tidak jadi unhandled exception.
  Future<void> _loadStoreInfo() async {
    try {
      final info = (await sl<SettingsRepository>().getStoreInfo()).getOrElse(
        () => const StoreInfo(),
      );
      if (mounted) setState(() => _store = info);
    } catch (_) {
      if (mounted) setState(() => _store = const StoreInfo());
    }
  }

  Future<void> _openStoreInfo() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const StoreInfoScreen()),
    );
    await _loadStoreInfo();
  }

  Future<void> _loadPinStatus() async {
    try {
      final hasPin = (await sl<PinRepository>().hasPin()).getOrElse(
        () => false,
      );
      if (mounted) setState(() => _hasPin = hasPin);
    } catch (_) {
      // Anggap belum ada PIN; barisnya mengajak membuat PIN.
      if (mounted) setState(() => _hasPin = false);
    }
  }

  Future<void> _openPinScreen() async {
    // Sudah ada PIN: buktikan dulu pemegangnya sebelum boleh menggantinya.
    if (_hasPin &&
        !await PinGate.require(
          context,
          reason: 'Diperlukan untuk mengganti PIN',
        )) {
      return;
    }
    if (!mounted) return;

    await context.push<bool>(PageRoutes.aturPin);
    await _loadPinStatus();
  }

  Future<void> _runBackup() async {
    if (await BackupAction.run(context)) {
      await _loadStoreInfo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup dibuat')),
        );
      }
    }
  }

  String get _lastBackupText {
    final last = _store.lastBackupAt;
    if (last == null) return 'Belum pernah';
    return DateFormat('dd/MM/yyyy HH.mm').format(last);
  }

  @override
  Widget build(BuildContext context) {
    final stale = _store.backupIsStale(DateTime.now());

    return Scaffold(
      backgroundColor: AppColor.bg,
      // App bar-nya wajib: sejak D2 layar ini di-push dari ikon gear di
      // Laporan, bukan tab lagi, jadi tanpa ini tidak ada jalan kembali.
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(
            top: AppSpacing.s2,
            bottom: AppSpacing.s6,
          ),
          children: [
            // Pengingat backup akhirnya punya rumah lagi: dulu di Dasbor yang
            // dibuang di D2 (ADR-047). Hanya muncul kalau sudah lewat ambang.
            if (stale)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  0,
                  AppSpacing.s4,
                  AppSpacing.s6,
                ),
                child: BackupReminder(store: _store),
              ),
            const SectionHeader(title: 'Backup & restore'),
            _BackupCard(
              lastBackupText: _lastBackupText,
              stale: stale,
              onBackup: _runBackup,
              onRestore: () => RestoreAction.run(context),
            ),
            const SizedBox(height: AppSpacing.s6),
            const SectionHeader(title: 'Toko'),
            AppCard(
              children: [
                _SettingRow(
                  title: 'Info toko',
                  subtitle: _store.name.isEmpty
                      ? 'Belum diisi — tidak muncul di struk'
                      : _store.name,
                  onTap: _openStoreInfo,
                ),
                _SettingRow(
                  title: _hasPin ? 'Ganti PIN' : 'Buat PIN',
                  subtitle: _hasPin
                      ? 'Melindungi void, restore, ubah harga, dan laba'
                      : 'Belum diatur — void dan restore belum terlindungi',
                  trailing: _hasPin
                      ? const AppBadge(
                          label: 'Aktif',
                          tone: BadgeTone.success,
                        )
                      : const AppBadge(
                          label: 'Belum ada',
                          tone: BadgeTone.warning,
                        ),
                  onTap: _openPinScreen,
                ),
                // Baris "Pajak (PPN) 11%" dan "Printer thermal BT-01" dihapus
                // di D8: keduanya dummy yang tidak pernah punya implementasi,
                // dan pajak termasuk out-of-scope (AGENTS.md §6 / PRD §1.4).
                // Baris "Isi: N produk · N transaksi" di mockup juga tidak
                // dibangun — keputusan pemilik 5, tidak ada query hitung baru.
                const _SettingRow(
                  title: 'Tentang Henshin',
                  subtitle: 'Versi 1.0.0 · offline-first',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupCard extends StatelessWidget {
  const _BackupCard({
    required this.lastBackupText,
    required this.stale,
    required this.onBackup,
    required this.onRestore,
  });

  final String lastBackupText;
  final bool stale;
  final VoidCallback onBackup;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup terakhir',
            style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  lastBackupText,
                  style: AppTextStyle.bodyStrong.copyWith(
                    color: AppColor.ink,
                  ),
                ),
              ),
              if (stale)
                const AppBadge(
                  label: 'Perlu backup',
                  tone: BadgeTone.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s3),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.tapPrimary,
            child: ElevatedButton.icon(
              onPressed: onBackup,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Buat backup'),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.tapMin,
            child: OutlinedButton.icon(
              onPressed: onRestore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore dari backup'),
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            'Restore butuh PIN dan mengganti semua data di HP ini dengan isi '
            'file backup.',
            style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// null = baris keterangan, bukan tombol: tanpa chevron dan tanpa efek ketuk.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.rowMin),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyle.body.copyWith(color: AppColor.ink),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s2),
            trailing!,
          ],
          if (onTap != null)
            Icon(Icons.chevron_right, color: AppColor.inkMuted),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

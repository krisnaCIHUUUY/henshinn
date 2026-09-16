import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _switchValue = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const Text(
              'Pengaturan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColor.onSurface,
              ),
            ),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Toko'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  title: 'Nama toko',
                  subtitle: 'Henshin Store',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColor.outline),
                  onTap: () {
                    // navigasi ke edit nama toko
                  },
                ),
                _SettingsRow(
                  title: 'Pajak (PPN)',
                  subtitle: 'Ditambahkan ke struk',
                  trailing: const Text(
                    '11%',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColor.onSurface,
                    ),
                  ),
                  onTap: () {
                    // navigasi ke pengaturan pajak
                  },
                ),
                _SettingsRow(
                  title: 'Printer thermal',
                  subtitle: 'Bluetooth · terhubung',
                  trailing: const _StatusBadge(label: 'BT-01'),
                  onTap: () {
                    // navigasi ke pengaturan printer
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Data lokal'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  title: 'Backup otomatis',
                  subtitle: 'Setiap hari · tersimpan lokal',
                  trailing: Switch(
                    value: _switchValue,
                    onChanged: (value) {
                      // toggle backup otomatis
                      setState(() {
                        _switchValue = value;
                      });
                    },
                    activeThumbColor: AppColor.surfaceContainerLowest,
                    activeTrackColor: AppColor.onSurface,
                  ),
                  onTap: null, // baris ini toggle langsung, bukan navigasi
                ),
                _SettingsRow(
                  title: 'Export laporan',
                  subtitle: 'CSV · periode bulan ini',
                  trailing: const Icon(Icons.chevron_right,
                      color: AppColor.outline),
                  onTap: () {
                    // navigasi ke export laporan
                  },
                  isLast: true,
                ),
              ],
            ),
            const SizedBox(height: 28),
            const _SectionLabel(label: 'Lainnya'),
            const SizedBox(height: 10),
            _SettingsGroup(
              children: [
                _SettingsRow(
                  title: 'Tentang Henshin',
                  subtitle: 'Versi 1.0.0 · offline-first',
                  trailing: const SizedBox.shrink(),
                  onTap: () {
                    // navigasi ke halaman about
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= SECTION LABEL =================

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyle.labelSm.copyWith(
        color: AppColor.outline,
        fontSize: 15,
      ),
    );
  }
}

// ================= SETTINGS GROUP (card container) =================

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(children: children),
    );
  }
}

// ================= SETTINGS ROW =================

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isLast = false,
  }) : titleColor = null;

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Color? titleColor;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      // splashColor: AppColor.onSecondaryContainer,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyle.bodyMd.copyWith(
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? AppColor.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColor.outline,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
          ),
          if (!isLast)
            const Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: AppColor.outlineVariant,
            ),
        ],
      ),
    );
  }
}

// ================= STATUS BADGE =================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColor.tertiaryFixed,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        label,
        style: AppTextStyle.labelSm.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColor.onTertiaryFixed,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class AppScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScreen({super.key, required this.navigationShell});

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNavBar({required this.currentIndex, required this.onTap});

  /// Urutannya harus sama dengan urutan branch di `app_router.dart`.
  static const _items = [
    _NavItemData(icon: Icons.point_of_sale, label: 'Kasir'),
    _NavItemData(icon: Icons.inventory_2_outlined, label: 'Produk'),
    _NavItemData(icon: Icons.receipt_long_outlined, label: 'Riwayat'),
    _NavItemData(icon: Icons.bar_chart, label: 'Laporan'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.surface,
        border: Border(top: BorderSide(color: AppColor.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: _NavItem(
                    icon: item.icon,
                    label: item.label,
                    selected: index == currentIndex,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;
  const _NavItemData({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColor.primary : AppColor.inkMuted;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tab aktif ditandai pil primarySoft, bukan hanya warna ikon — warna
        // saja tidak cukup untuk yang sulit membedakan warna.
        Container(
          width: 56,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColor.primarySoft : Colors.transparent,
            borderRadius: AppRadius.fullAll,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: AppSpacing.s1),
        Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: color,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

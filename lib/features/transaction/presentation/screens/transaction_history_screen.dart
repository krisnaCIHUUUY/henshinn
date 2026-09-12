import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Hari ini, 1: 7 hari, 2: 30 hari

  final List<String> _filters = ['Hari ini', '7 hari', '30 hari'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeaderRow(),
                  const SizedBox(height: AppSpacing.lg - 4),
                  _FilterTabs(
                    filters: _filters,
                    selectedIndex: _selectedFilterIndex,
                    onSelected: (index) {
                      setState(() => _selectedFilterIndex = index);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: const [
                  _TransactionTile(
                    invoiceId: 'INV-0911-024',
                    time: '12:20',
                    itemCount: 5,
                    amount: 'Rp 76.000',
                    status: _TransactionStatus.lunas,
                  ),
                  Divider(height: 1, color: AppColor.divider),
                  _TransactionTile(
                    invoiceId: 'INV-0911-023',
                    time: '11:45',
                    itemCount: 1,
                    amount: 'Rp 25.000',
                    status: _TransactionStatus.lunas,
                  ),
                  Divider(height: 1, color: AppColor.divider),
                  _TransactionTile(
                    invoiceId: 'INV-0911-019',
                    time: '10:02',
                    itemCount: 5,
                    amount: 'Rp 128.500',
                    status: _TransactionStatus.lunas,
                  ),
                  Divider(height: 1, color: AppColor.divider),
                  _TransactionTile(
                    invoiceId: 'INV-0911-012',
                    time: '09:15',
                    itemCount: 1,
                    amount: 'Rp 85.000',
                    status: _TransactionStatus.void_,
                  ),
                  Divider(height: 1, color: AppColor.divider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// HEADER ROW 

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Riwayat',
          style: AppTextStyle.headlineLg.copyWith(color: AppColor.onSurface),
        ),
        Container(
          width: AppSpacing.touchTargetMin,
          height: AppSpacing.touchTargetMin,
          decoration: BoxDecoration(
            color: AppColor.surfaceContainerLowest,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColor.outlineVariant),
          ),
          child: Icon(
            Icons.file_download_outlined,
            color: AppColor.onSurface,
          ),
        ),
      ],
    );
  }
}

//  FILTER TABS 

class _FilterTabs extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _FilterTabs({
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(filters.length, (index) {
        final selected = index == selectedIndex;
        return Padding(
          padding: EdgeInsets.only(right: index != filters.length - 1 ? AppSpacing.sm + 2 : 0),
          child: GestureDetector(
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md - 4),
              decoration: BoxDecoration(
                color: selected ? AppColor.onSurface : AppColor.surfaceContainerLowest,
                borderRadius: AppRadius.mdAll,
                border: Border.all(
                  color: selected ? AppColor.onSurface : AppColor.outlineVariant,
                ),
              ),
              child: Text(
                filters[index],
                style: AppTextStyle.labelSm.copyWith(
                  color: selected ? AppColor.onPrimary : AppColor.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

//TRANSACTION TILE

enum _TransactionStatus { lunas, void_ }

class _TransactionTile extends StatelessWidget {
  final String invoiceId;
  final String time;
  final int itemCount;
  final String amount;
  final _TransactionStatus status;

  const _TransactionTile({
    required this.invoiceId,
    required this.time,
    required this.itemCount,
    required this.amount,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // navigasi ke detail transaksi
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceId,
                  style: AppTextStyle.bodyLg.copyWith(
                    color: AppColor.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$time · $itemCount item',
                  style: AppTextStyle.labelSm.copyWith(
                    color: AppColor.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  amount,
                  style: AppTextStyle.headlineMd.copyWith(
                    color: AppColor.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs + 2),
                _StatusBadge(status: status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _TransactionStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isLunas = status == _TransactionStatus.lunas;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md - 2,
        vertical: AppSpacing.xs + 1,
      ),
      decoration: BoxDecoration(
        color: isLunas ? AppColor.primaryFixed.withValues(alpha: 0.2) : AppColor.errorContainer,
        borderRadius: AppRadius.fullAll,
      ),
      child: Text(
        isLunas ? 'Lunas' : 'Void',
        style: AppTextStyle.labelSm.copyWith(
          color: isLunas ? AppColor.primaryFixedDim : AppColor.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/transaction/domain/entities/transaction_summary.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:henshin/injection_container.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilterIndex = 0; // 0: Hari ini, 1: 7 hari, 2: 30 hari

  final List<String> _filters = ['Hari ini', '7 hari', '30 hari'];

  /// Batas awal per filter. "Hari ini" = tengah malam lokal, bukan 24 jam ke
  /// belakang, supaya cocok dengan cara pemilik menghitung harinya.
  DateTime get _since {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_selectedFilterIndex) {
      0 => today,
      1 => today.subtract(const Duration(days: 6)),
      _ => today.subtract(const Duration(days: 29)),
    };
  }

  // Stream disimpan, bukan dibuat di build(): tiap build baru akan
  // berlangganan ulang dan membuat list berkedip ke spinner.
  late Stream<List<TransactionSummary>> _stream = _watch();

  Stream<List<TransactionSummary>> _watch() =>
      sl<TransactionRepository>().watchHistory(since: _since);

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
                      setState(() {
                        _selectedFilterIndex = index;
                        _stream = _watch();
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<TransactionSummary>>(
                // Stream Drift: setelah void, list menyegarkan dirinya sendiri.
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _EmptyOrError(
                      message: 'Gagal memuat riwayat: ${snapshot.error}',
                    );
                  }
                  final items = snapshot.data;
                  if (items == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const _EmptyOrError(
                      message: 'Belum ada transaksi di periode ini',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColor.divider),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _TransactionTile(
                        invoiceId: '#${item.id}',
                        time: DateFormat(
                          'dd/MM HH:mm',
                        ).format(item.dateTime),
                        itemCount: item.itemCount,
                        amount: formatRupiah(item.total),
                        status: item.isVoided
                            ? _TransactionStatus.void_
                            : _TransactionStatus.lunas,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                TransactionDetailScreen(transactionId: item.id),
                          ),
                        ),
                      );
                    },
                  );
                },
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

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColor.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final String invoiceId;
  final String time;
  final int itemCount;
  final String amount;
  final _TransactionStatus status;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.invoiceId,
    required this.time,
    required this.itemCount,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/report/domain/repositories/report_repository.dart';
import 'package:henshin/features/report/presentation/widgets/report_stats.dart';
import 'package:henshin/injection_container.dart';

/// Laporan penjualan per preset (US-4.3). Rentang bebas sengaja tidak ada —
/// garis potong PRD §3.2.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  ReportPeriod _period = ReportPeriod.hariIni;
  SalesReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final requested = _period;
    try {
      final result = await sl<ReportRepository>().getReport(requested);
      // Preset bisa ditukar sebelum query selesai; hasil yang basi dibuang
      // supaya angkanya tidak menempel di label periode yang salah.
      if (!mounted || requested != _period) return;

      result.fold(
        (failure) => setState(() {
          _error = failure.message;
          _report = null;
        }),
        (report) => setState(() {
          _report = report;
          _error = null;
        }),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat laporan: $e';
        _report = null;
      });
    }
  }

  void _select(ReportPeriod period) {
    if (period == _period) return;
    setState(() {
      _period = period;
      _report = null;
      _error = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: const Text('Laporan'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  for (final period in ReportPeriod.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm + 2),
                      child: _PeriodChip(
                        label: period.label,
                        selected: period == _period,
                        onTap: () => _select(period),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch ((report, _error)) {
                (_, final String error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          error,
                          textAlign: TextAlign.center,
                          style: AppTextStyle.bodyMd.copyWith(
                            color: AppColor.error,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton(
                          onPressed: _load,
                          child: const Text('Coba lagi'),
                        ),
                      ],
                    ),
                  ),
                ),
                (null, _) => const Center(child: CircularProgressIndicator()),
                (final SalesReport r, _) => _ReportBody(report: r),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: const BoxDecoration(
            color: AppColor.surfaceContainerLow,
            borderRadius: AppRadius.lgAll,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Omzet · ${report.period.label.toLowerCase()}',
                style: AppTextStyle.labelSm.copyWith(
                  color: AppColor.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(report.revenue),
                  style: AppTextStyle.headlineLg.copyWith(
                    color: AppColor.onSurface,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Laba kotor ${formatRupiah(report.grossProfit)}',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColor.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: StatBox(
                label: 'Transaksi',
                value: '${report.transactionCount}',
              ),
            ),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: StatBox(
                label: 'Item terjual',
                value: '${report.itemCount}',
              ),
            ),
            const SizedBox(width: AppSpacing.md - 4),
            Expanded(
              child: StatBox(
                label: 'Rata-rata',
                value: formatRupiah(report.averageSale),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Produk terlaris',
          style: AppTextStyle.headlineMd.copyWith(
            color: AppColor.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        BestSellerList(
          items: report.bestSellers,
          empty: 'Belum ada penjualan di periode ini',
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Transaksi yang sudah di-void tidak dihitung.',
          style: AppTextStyle.labelSm.copyWith(color: AppColor.outline),
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md - 4,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColor.onSurface
              : AppColor.surfaceContainerLowest,
          borderRadius: AppRadius.mdAll,
          border: Border.all(
            color: selected ? AppColor.onSurface : AppColor.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyle.labelSm.copyWith(
            color: selected ? AppColor.onPrimary : AppColor.onSurface,
          ),
        ),
      ),
    );
  }
}

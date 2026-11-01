import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/report/domain/repositories/report_repository.dart';
import 'package:henshin/features/report/presentation/widgets/report_stats.dart';
import 'package:henshin/injection_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  SalesReport? _today;
  SalesReport? _week;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Dua laporan: angka hari ini (US-4.1) dan 7 hari untuk batang trennya.
  ///
  /// Future, bukan stream: dashboard ini hidup di `IndexedStack` jadi tidak
  /// dibangun ulang saat tab ditukar — penyegaran dipicu tarik-ke-bawah dan
  /// saat kembali dari kasir.
  Future<void> _load() async {
    try {
      final repository = sl<ReportRepository>();
      final today = await repository.getReport(ReportPeriod.hariIni);
      final week = await repository.getReport(ReportPeriod.tujuhHari);
      if (!mounted) return;

      setState(() {
        today.fold((f) => _error = f.message, (r) {
          _today = r;
          _error = null;
        });
        week.fold((f) => _error = f.message, (r) => _week = r);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal memuat dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final week = _week;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GreetingHeader(),
                const SizedBox(height: AppSpacing.lg - 4),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      _error!,
                      style: AppTextStyle.bodyMd.copyWith(
                        color: AppColor.error,
                      ),
                    ),
                  ),
                if (today == null || week == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else ...[
                  _RevenueCard(today: today, week: week),
                  const SizedBox(height: AppSpacing.md),
                  _StatsRow(report: today),
                  const SizedBox(height: AppSpacing.lg + 4),
                  const _SectionTitle(title: 'Produk terlaris hari ini'),
                  const SizedBox(height: AppSpacing.xs),
                  BestSellerList(
                    items: today.bestSellers,
                    empty: 'Belum ada penjualan hari ini',
                  ),
                ],
                const SizedBox(height: AppSpacing.lg - 4),
                _StartTransactionButton(onReturn: _load),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Henshin',
                style: AppTextStyle.headlineMd.copyWith(
                  color: AppColor.onSurface,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Henshin Store · kasir 1',
                style: AppTextStyle.bodyMd.copyWith(
                  color: AppColor.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: () => context.push(PageRoutes.laporan),
          icon: const Icon(Icons.bar_chart, size: 18),
          label: const Text('Laporan'),
          style: TextButton.styleFrom(foregroundColor: AppColor.onSurface),
        ),
      ],
    );
  }
}

//  REVENUE CARD

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.today, required this.week});

  final SalesReport today;
  final SalesReport week;

  @override
  Widget build(BuildContext context) {
    final daily = week.daily;
    final yesterday = daily.length < 2 ? 0 : daily[daily.length - 2].revenue;
    final growth = yesterday == 0
        ? null
        : ((today.revenue - yesterday) / yesterday * 100).round();

    return Container(
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
            'Pendapatan hari ini',
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatRupiah(today.revenue),
                    style: AppTextStyle.headlineLg.copyWith(
                      color: AppColor.onSurface,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              // Badge hanya kalau ada pembanding: tanpa penjualan kemarin,
              // persentasenya tidak punya arti.
              if (growth != null) ...[
                const SizedBox(width: AppSpacing.sm + 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2,
                    vertical: AppSpacing.xs + 1,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColor.tertiaryFixed,
                    borderRadius: AppRadius.fullAll,
                  ),
                  child: Text(
                    '${growth >= 0 ? '+' : ''}$growth%',
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.tertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(height: 130, child: _RevenueChart(daily: daily)),
        ],
      ),
    );
  }
}

/// Omzet 7 hari. Ketuk satu batang untuk angka hari itu — itulah alasan
/// memakai fl_chart dan bukan batang buatan sendiri: tooltipnya membuat tiap
/// hari bisa dibaca persis, bukan cuma dibandingkan tingginya.
class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.daily});

  final List<DailyRevenue> daily;

  static const _dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  @override
  Widget build(BuildContext context) {
    final peak = daily.fold(0, (m, d) => d.revenue > m ? d.revenue : m);

    return BarChart(
      BarChartData(
        // Skala tetap 1 kalau belum ada penjualan sama sekali, supaya chart
        // tidak mencoba membagi dengan nol.
        maxY: peak == 0 ? 1 : peak * 1.15,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= daily.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  space: AppSpacing.sm,
                  child: Text(
                    _dayLabels[daily[index].date.weekday - 1],
                    style: AppTextStyle.labelSm.copyWith(
                      color: AppColor.onSurfaceVariant,
                      fontWeight: index == daily.length - 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColor.onSurface,
            getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                BarTooltipItem(
                  formatRupiah(daily[group.x].revenue),
                  AppTextStyle.labelSm.copyWith(
                    color: AppColor.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < daily.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  // Hari tanpa penjualan tetap menyisakan garis tipis, supaya
                  // terbaca "nol", bukan "tidak ada datanya".
                  toY: daily[i].revenue == 0
                      ? (peak == 0 ? 1 : peak * 1.15) * 0.02
                      : daily[i].revenue.toDouble(),
                  width: 32,
                  borderRadius: AppRadius.defaultAll,
                  color: i == daily.length - 1
                      ? AppColor.primary
                      : AppColor.secondaryFixed,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// STATS ROW

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.report});

  final SalesReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatBox(
            label: 'Transaksi',
            value: '${report.transactionCount}',
          ),
        ),
        const SizedBox(width: AppSpacing.md - 4),
        Expanded(
          child: StatBox(label: 'Item terjual', value: '${report.itemCount}'),
        ),
        const SizedBox(width: AppSpacing.md - 4),
        Expanded(
          child: StatBox(
            label: 'Laba kotor',
            value: formatRupiah(report.grossProfit),
          ),
        ),
      ],
    );
  }
}

// ================= SECTION TITLE =================

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyle.headlineMd.copyWith(
        color: AppColor.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

// ================= RESTOCK LIST =================

// class _RestockList extends StatelessWidget {
//   const _RestockList();

//   @override
//   Widget build(BuildContext context) {
//     final items = [
//       _RestockItem(
//         initial: 'K',
//         name: 'Kopi Susu Henshin',
//         category: 'Minuman',
//         remaining: 'Sisa 3',
//       ),
//       _RestockItem(
//         initial: 'S',
//         name: 'Stiker Henshin',
//         category: 'Merchandise',
//         remaining: 'Sisa 2',
//       ),
//     ];

//     return Column(
//       children: [
//         for (int i = 0; i < items.length; i++) ...[
//           _RestockTile(item: items[i]),
//           if (i != items.length - 1)
//             Divider(height: 1, color: AppColor.divider),
//         ],
//       ],
//     );
//   }
// }

// class _RestockItem {
//   final String initial;
//   final String name;
//   final String category;
//   final String remaining;

//   _RestockItem({
//     required this.initial,
//     required this.name,
//     required this.category,
//     required this.remaining,
//   });
// }

// class _RestockTile extends StatelessWidget {
//   final _RestockItem item;
//   const _RestockTile({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: AppSpacing.md - 2),
//       child: Row(
//         children: [
//           CircleAvatar(
//             radius: 20,
//             backgroundColor: AppColor.surfaceContainerHigh,
//             child: Text(
//               item.initial,
//               style: AppTextStyle.labelSm.copyWith(
//                 color: AppColor.onSurface,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(width: AppSpacing.md - 2),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   item.name,
//                   style: AppTextStyle.bodyMd.copyWith(
//                     color: AppColor.onSurface,
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//                 const SizedBox(height: AppSpacing.xs - 2),
//                 Text(
//                   item.category,
//                   style: AppTextStyle.labelSm.copyWith(
//                     color: AppColor.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             padding: const EdgeInsets.symmetric(
//               horizontal: AppSpacing.md - 4,
//               vertical: AppSpacing.xs + 2,
//             ),
//             decoration: const BoxDecoration(
//               color: AppColor.tertiaryFixedDim,
//               borderRadius: AppRadius.fullAll,
//             ),
//             child: Text(
//               item.remaining,
//               style: AppTextStyle.labelSm.copyWith(
//                 color: AppColor.onTertiaryFixed,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ================= START TRANSACTION BUTTON =================

class _StartTransactionButton extends StatelessWidget {
  const _StartTransactionButton({required this.onReturn});

  /// Dashboard tidak dibangun ulang sendiri setelah transaksi, jadi angkanya
  /// dimuat ulang begitu kasir ditutup.
  final Future<void> Function() onReturn;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.xxxl + AppSpacing.sm + 2,
      child: ElevatedButton.icon(
        onPressed: () async {
          // push, bukan go: kasir ditumpuk di atas dashboard supaya tombol
          // kembali di AppBar dan tombol back fisik sama-sama berfungsi.
          await context.push(PageRoutes.mulaiTransaksi);
          await onReturn();
        },
        icon: const Icon(Icons.add, color: AppColor.onPrimary),
        label: Text(
          'Mulai transaksi baru',
          style: AppTextStyle.bodyMd.copyWith(
            color: AppColor.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
      ),
    );
  }
}

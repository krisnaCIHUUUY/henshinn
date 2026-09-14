import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/page_routes.dart';

class DashboardScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // _TopBar(),
              // const SizedBox(height: 24),
              _GreetingHeader(),
              const SizedBox(height: AppSpacing.lg - 4),
              _RevenueCard(),
              const SizedBox(height: AppSpacing.md),
              _StatsRow(),
              const SizedBox(height: AppSpacing.lg + 4),
              _SectionTitle(title: 'Produk terlaris'),
              const SizedBox(height: AppSpacing.xs),
              _BestSellerList(),
              const SizedBox(height: AppSpacing.lg - 4),
              _StartTransactionButton(),
              const SizedBox(height: AppSpacing.lg),
            ],
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
      ],
    );
  }
}

//  REVENUE CARD

class _RevenueCard extends StatelessWidget {
  const _RevenueCard();

  @override
  Widget build(BuildContext context) {
    // data tren 7 hari — hardcoded sesuai referensi untuk keperluan UI
    final trend = <_TrendPoint>[
      _TrendPoint('Sen', 0.45),
      _TrendPoint('Sel', 0.60),
      _TrendPoint('Rab', 0.42),
      _TrendPoint('Kam', 0.65),
      _TrendPoint('Jum', 0.50),
      _TrendPoint('Sab', 0.90),
      _TrendPoint('Min', 0.68, highlighted: true),
    ];

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
              Text(
                'Rp 1.284.500',
                style: AppTextStyle.headlineLg.copyWith(
                  color: AppColor.onSurface,
                  height: 1.0,
                ),
              ),
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
                  '+12%',
                  style: AppTextStyle.labelSm.copyWith(
                    color: AppColor.tertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: trend
                  .map((point) => Expanded(child: _BarColumn(point: point)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendPoint {
  final String label;
  final double heightFactor; // 0.0 - 1.0
  final bool highlighted;

  _TrendPoint(this.label, this.heightFactor, {this.highlighted = false});
}

class _BarColumn extends StatelessWidget {
  final _TrendPoint point;
  const _BarColumn({required this.point});

  static const double maxBarHeight = 100;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: maxBarHeight * point.heightFactor,
            decoration: BoxDecoration(
              color: point.highlighted
                  ? AppColor.primary
                  : AppColor.secondaryFixed,
              borderRadius: AppRadius.defaultAll,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Text(
            point.label,
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onSurfaceVariant,
              fontWeight: point.highlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// STATS ROW

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatBox(label: 'Transaksi', value: '24'),
        ),
        SizedBox(width: AppSpacing.md - 4),
        Expanded(
          child: _StatBox(label: 'Item terjual', value: '86'),
        ),
        SizedBox(width: AppSpacing.md - 4),
        Expanded(
          child: _StatBox(label: 'Rata-rata', value: '53rb'),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md + 2,
      ),
      decoration: const BoxDecoration(
        color: AppColor.surfaceContainerLow,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            value,
            style: AppTextStyle.headlineMd.copyWith(
              color: AppColor.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

// ================= BEST SELLER LIST =================

class _BestSellerItem {
  final int rank;
  final String name;
  final String soldLabel;

  _BestSellerItem({
    required this.rank,
    required this.name,
    required this.soldLabel,
  });
}

class _BestSellerList extends StatelessWidget {
  const _BestSellerList();

  @override
  Widget build(BuildContext context) {
    final items = [
      _BestSellerItem(
        rank: 1,
        name: 'Kopi Susu Henshin',
        soldLabel: '42 terjual',
      ),
      _BestSellerItem(
        rank: 2,
        name: 'Es Kopi Gula Aren',
        soldLabel: '38 terjual',
      ),
      _BestSellerItem(rank: 3, name: 'Matcha Latte', soldLabel: '21 terjual'),
    ];

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _BestSellerTile(item: items[i]),
          if (i != items.length - 1)
            Divider(height: 1, color: AppColor.divider),
        ],
      ],
    );
  }
}

class _BestSellerTile extends StatelessWidget {
  final _BestSellerItem item;
  const _BestSellerTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${item.rank}',
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColor.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md - 4),
          Expanded(
            child: Text(
              item.name,
              style: AppTextStyle.bodyMd.copyWith(
                color: AppColor.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            item.soldLabel,
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ================= START TRANSACTION BUTTON =================

class _StartTransactionButton extends StatelessWidget {
  const _StartTransactionButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.xxxl + AppSpacing.sm + 2,
      child: ElevatedButton.icon(
        onPressed: () {
          // navigasi ke flow kasir
          context.go(PageRoutes.mulaiTransaksi);
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

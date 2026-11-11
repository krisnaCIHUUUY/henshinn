import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/core/widgets/app_badge.dart';
import 'package:henshin/core/widgets/app_card.dart';
import 'package:henshin/core/widgets/app_chip.dart';
import 'package:henshin/core/widgets/section_header.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/report/domain/repositories/report_repository.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/injection_container.dart';

/// Laporan penjualan per preset (US-4.3). Rentang bebas sengaja tidak ada —
/// garis potong PRD §3.2, jadi chip "Pilih" di mockup v2 tidak dibangun.
///
/// Layar ini juga mewarisi angka hari ini dari Dasbor yang dibuang di D2
/// (ADR-047), dan jadi satu-satunya pintu ke Pengaturan.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen>
    with WidgetsBindingObserver {
  ReportPeriod _period = ReportPeriod.hariIni;
  SalesReport? _report;
  String? _error;

  /// Laba kotor hanya terlihat setelah PIN benar (PRD §1.6, ADR-057).
  bool _profitVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Ringkasan "Perlu restok" memakai daftar yang sama dengan chip di layar
    // Produk; tanpa ini daftarnya kosong kalau pemilik belum pernah ke sana.
    context.read<ProductBloc>().add(const ProductEvent.lowStockRequested());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // HP dikunci atau aplikasi ditinggalkan: laba dikunci lagi. Tanpa ini
    // angka laba tetap terbuka di layar yang ditinggalkan menyala.
    if (state != AppLifecycleState.resumed && _profitVisible) {
      setState(() => _profitVisible = false);
    }
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
      // Ganti periode berarti angka laba yang lain: PIN-nya diminta lagi,
      // bukan diwariskan ke periode yang belum pernah dibuka (ADR-057).
      _profitVisible = false;
    });
    _load();
  }

  /// `PinGate.require` sekaligus menangani kasus "PIN belum pernah dibuat":
  /// pesannya mengarahkan ke Pengaturan dan laba tetap tertutup.
  Future<void> _revealProfit() async {
    if (_profitVisible) return;
    final allowed = await PinGate.require(
      context,
      reason: 'Diperlukan untuk melihat laba kotor',
    );
    if (allowed && mounted) setState(() => _profitVisible = true);
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;

    return Scaffold(
      backgroundColor: AppColor.bg,
      appBar: AppBar(
        title: Text(
          'Laporan',
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
        // Pengaturan bukan tab lagi (D2) — ini satu-satunya pintunya.
        actions: [
          IconButton(
            tooltip: 'Pengaturan',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(PageRoutes.setting),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            ChipRow(
              children: [
                for (final period in ReportPeriod.values)
                  AppChip(
                    label: period.label,
                    selected: period == _period,
                    onTap: () => _select(period),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: switch ((report, _error)) {
                (_, final String error) => _ErrorView(
                  message: error,
                  onRetry: _load,
                ),
                (null, _) => const Center(child: CircularProgressIndicator()),
                (final SalesReport r, _) => _ReportBody(
                  report: r,
                  profitVisible: _profitVisible,
                  onRevealProfit: _revealProfit,
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyle.body.copyWith(color: AppColor.danger),
            ),
            const SizedBox(height: AppSpacing.s4),
            OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.report,
    required this.profitVisible,
    required this.onRevealProfit,
  });

  final SalesReport report;
  final bool profitVisible;
  final VoidCallback onRevealProfit;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.s6),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Column(
            children: [
              _StatTile(
                label: 'Omzet ${report.period.label.toLowerCase()}',
                value: formatRupiah(report.revenue),
                big: true,
              ),
              const SizedBox(height: AppSpacing.s3),
              // `stretch` sendirian di dalam ListView meminta tinggi tak
              // terbatas dan langsung crash. IntrinsicHeight yang memberi
              // Row tinggi nyata, supaya kedua kartu tetap sama tinggi
              // walau ikon kunci membuat satu sisi lebih tinggi.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: 'Laba kotor',
                        // Titik, bukan angka acak: angka palsu bisa terbaca
                        // sebagai laba yang sebenarnya.
                        value: profitVisible
                            ? formatRupiah(report.grossProfit)
                            : '••••••',
                        locked: !profitVisible,
                        onTap: profitVisible ? null : onRevealProfit,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: _StatTile(
                        label: 'Transaksi',
                        value: '${report.transactionCount}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.s6),
        const SectionHeader(title: 'Terlaris'),
        if (report.bestSellers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
            child: Text(
              'Belum ada penjualan di periode ini',
              style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
            ),
          )
        else
          AppCard(
            children: [
              for (var i = 0; i < report.bestSellers.length; i++)
                _BestSellerRow(rank: i + 1, item: report.bestSellers[i]),
            ],
          ),
        const SizedBox(height: AppSpacing.s6),
        const _LowStockSummary(),
        const SizedBox(height: AppSpacing.s4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
          child: Text(
            'Transaksi yang sudah di-void tidak dihitung.',
            style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// Kartu angka. `big` untuk omzet (satu per layar), sisanya berdampingan.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.big = false,
    this.locked = false,
    this.onTap,
  });

  final String label;
  final String value;
  final bool big;
  final bool locked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColor.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
                ),
              ),
              if (locked) ...[
                const SizedBox(width: AppSpacing.s1),
                Icon(
                  Icons.lock_outline,
                  size: 16,
                  color: AppColor.inkMuted,
                  semanticLabel: 'Dilindungi PIN',
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: big
                  ? AppTextStyle.amount.copyWith(color: AppColor.ink)
                  : AppTextStyle.stat.copyWith(color: AppColor.ink),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.mdAll,
      child: card,
    );
  }
}

class _BestSellerRow extends StatelessWidget {
  const _BestSellerRow({required this.rank, required this.item});

  final int rank;
  final BestSeller item;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.tapPrimary),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              style: AppTextStyle.bodyStrong.copyWith(
                color: AppColor.inkMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.body.copyWith(color: AppColor.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Text(
            '${item.qtySold} terjual',
            style: AppTextStyle.label.copyWith(color: AppColor.inkMuted),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan produk yang perlu restok, memakai daftar yang sama dengan chip
/// "Perlu restok · N" di layar Produk — tidak ada query baru (ADR-052).
class _LowStockSummary extends StatelessWidget {
  const _LowStockSummary();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductBloc, ProductState>(
      buildWhen: (p, c) => p.lowStockProducts != c.lowStockProducts,
      builder: (context, state) {
        final products = state.lowStockProducts;
        if (products.isEmpty) return const SizedBox.shrink();

        // Tiga teratas saja: daftar lengkapnya ada di layar Produk, dan
        // laporan bukan tempat mengelola stok.
        final shown = products.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Perlu restok',
              trailing: TextButton(
                // Pindah tab, bukan push: Produk adalah cabang shell sendiri.
                onPressed: () => context.go(PageRoutes.produk),
                child: const Text('Lihat semua'),
              ),
            ),
            AppCard(
              children: [
                for (final product in shown) _LowStockRow(product: product),
              ],
            ),
            if (products.length > shown.length)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s4,
                  AppSpacing.s2,
                  AppSpacing.s4,
                  0,
                ),
                child: Text(
                  '+${products.length - shown.length} produk lainnya',
                  style: AppTextStyle.label.copyWith(
                    color: AppColor.inkMuted,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: AppSpacing.tapMin + 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s2,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.body.copyWith(color: AppColor.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          product.isOutOfStock
              ? const AppBadge(label: 'Habis', tone: BadgeTone.danger)
              : AppBadge(
                  label: 'Sisa ${product.stock}',
                  tone: BadgeTone.warning,
                ),
        ],
      ),
    );
  }
}

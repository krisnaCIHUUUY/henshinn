import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/product/presentation/bloc/product_event.dart';
import 'package:henshin/features/product/presentation/bloc/product_state.dart';
import 'package:henshin/features/product/presentation/widgets/stock_sheet.dart';

/// Daftar belanja pemilik (PRD US-2.4). Batasnya per produk, dan produk
/// nonaktif tidak ikut karena tidak dijual.
class LowStockScreen extends StatefulWidget {
  const LowStockScreen({super.key});

  @override
  State<LowStockScreen> createState() => _LowStockScreenState();
}

class _LowStockScreenState extends State<LowStockScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const ProductEvent.lowStockRequested());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: const Text('Perlu Restok'),
      ),
      body: SafeArea(
        child: BlocBuilder<ProductBloc, ProductState>(
          buildWhen: (previous, current) =>
              previous.lowStockProducts != current.lowStockProducts,
          builder: (context, state) {
            final products = state.lowStockProducts;

            if (products.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Text(
                    'Semua stok masih aman.',
                    textAlign: TextAlign.center,
                    style: AppTextStyle.bodyMd.copyWith(
                      color: AppColor.outline,
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final product = products[index];
                return Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColor.surfaceContainerLowest,
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(color: AppColor.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: AppTextStyle.bodyMd.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColor.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              product.isOutOfStock
                                  ? 'Stok habis · batas ${product.lowStockThreshold}'
                                  : 'Sisa ${product.stock} · batas ${product.lowStockThreshold}',
                              style: AppTextStyle.labelSm.copyWith(
                                color: product.isOutOfStock
                                    ? AppColor.error
                                    : AppColor.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => StockSheet.show(
                          context,
                          product: product,
                          mode: StockSheetMode.restock,
                        ),
                        child: const Text('Restok'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

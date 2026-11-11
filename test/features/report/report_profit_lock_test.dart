import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/repositories/product_repository.dart';
import 'package:henshin/features/product/domain/usecases/add_product.dart';
import 'package:henshin/features/product/domain/usecases/delete_product.dart';
import 'package:henshin/features/product/domain/usecases/update_product.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/report/domain/repositories/report_repository.dart';
import 'package:henshin/features/report/presentation/screens/report_screen.dart';
import 'package:henshin/injection_container.dart';

/// Laba kotor ber-PIN (PRD §1.6, ADR-057). Yang diuji di sini **bukan** PIN-nya
/// — itu sudah dijaga `pin_flow_widget_test` dan `pin_repository_impl_test` —
/// tapi satu hal yang lebih mudah rusak tanpa sadar: angka labanya tidak boleh
/// ada di widget tree sebelum PIN benar. Menyembunyikannya dengan `Opacity`
/// atau warna transparan akan lolos mata tapi gagal di sini.
///
/// Tes geometri/UI murni: semua repository dipalsukan, tidak ada DB dan tidak
/// ada stream Drift yang menggantung (ADR-012).
class _FakeReportRepository extends Fake implements ReportRepository {
  @override
  Future<Either<Failure, SalesReport>> getReport(ReportPeriod period) async {
    return Right(
      SalesReport(
        period: period,
        revenue: 1284500,
        grossProfit: 312000,
        transactionCount: 24,
        itemCount: 61,
        bestSellers: const [BestSeller(name: 'Mi Goreng Instan', qtySold: 12)],
        daily: const [],
      ),
    );
  }
}

class _FakeProductRepository extends Fake implements ProductRepository {
  @override
  Stream<List<ProductEntity>> watchAllProducts() => Stream.value(const []);

  @override
  Stream<List<CategoryEntity>> watchCategories() => Stream.value(const []);

  @override
  Stream<List<ProductEntity>> watchLowStockProducts() =>
      Stream.value(const []);
}

void main() {
  setUp(() {
    sl.registerLazySingleton<ReportRepository>(_FakeReportRepository.new);
  });

  tearDown(sl.reset);

  Future<void> pumpReport(WidgetTester tester) async {
    final repository = _FakeProductRepository();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: BlocProvider<ProductBloc>(
          create: (_) => ProductBloc(
            repository: repository,
            addProduct: AddProduct(repository),
            updateProduct: UpdateProduct(repository),
            deleteProduct: DeleteProduct(repository),
          ),
          child: const ReportScreen(),
        ),
      ),
    );
    // getReport dipalsukan async, jadi butuh satu putaran sebelum angkanya ada.
    await tester.pump();
    await tester.pump();
  }

  testWidgets('laba kotor tertutup sebelum PIN, omzet tidak', (tester) async {
    await pumpReport(tester);

    // Omzet dan jumlah transaksi memang terbuka: yang di-PIN hanya laba.
    expect(find.text('Rp 1.284.500'), findsOneWidget);
    expect(find.text('24'), findsOneWidget);

    // Yang penting: angkanya benar-benar tidak ada, bukan hanya tak terlihat.
    expect(find.text('Rp 312.000'), findsNothing);
    expect(find.text('••••••'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
  });

  testWidgets('judul omzet mengikuti periode yang dipilih', (tester) async {
    await pumpReport(tester);
    expect(find.text('Omzet hari ini'), findsOneWidget);

    await tester.tap(find.text('Bulan ini'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Omzet bulan ini'), findsOneWidget);
    // Ganti periode mengunci laba lagi — angka periode baru belum pernah
    // dibuka dengan PIN (ADR-057).
    expect(find.text('Rp 312.000'), findsNothing);
    expect(find.text('••••••'), findsOneWidget);
  });
}

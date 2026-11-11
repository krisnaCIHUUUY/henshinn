import 'package:go_router/go_router.dart';
import 'package:henshin/app.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';
import 'package:henshin/features/report/presentation/screens/report_screen.dart';
import 'package:henshin/features/setting/presentation/screens/pin_create_screen.dart';
import 'package:henshin/features/setting/presentation/screens/setting_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/cashier_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: PageRoutes.kasir,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScreen(navigationShell: navigationShell);
      },
      branches: [
        // branch kasir — tab pertama dan layar pembuka. CartBloc-nya di
        // main.dart, di atas shell ini, supaya keranjang tidak hilang saat
        // pemilik pindah tab di tengah transaksi (ADR-048).
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.kasir,
              name: PageRoutes.kasirName,
              builder: (context, state) => const CashierScreen(),
            ),
          ],
        ),

        // branch produk
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.produk,
              name: PageRoutes.produkName,
              builder: (context, state) => ProductListScreen(),
            ),
          ],
        ),

        // branch riwayat
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.riwayat,
              name: PageRoutes.riwayatName,
              builder: (context, state) => const TransactionHistoryScreen(),
            ),
          ],
        ),

        // branch laporan
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.laporan,
              name: PageRoutes.laporanName,
              builder: (context, state) => const ReportScreen(),
            ),
          ],
        ),
      ],
    ),

    // Pengaturan bukan tab lagi: dibuka dari ikon gear di app bar Laporan.
    GoRoute(
      path: PageRoutes.setting,
      name: PageRoutes.settingName,
      builder: (context, state) => SettingScreen(),
    ),

    GoRoute(
      path: PageRoutes.aturPin,
      name: PageRoutes.aturPinName,
      builder: (context, state) => const PinCreateScreen(),
    ),
  ],
);

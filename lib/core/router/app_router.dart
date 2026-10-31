import 'package:go_router/go_router.dart';
import 'package:henshin/app.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:henshin/features/product/presentation/screens/low_stock_screen.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';
import 'package:henshin/features/setting/presentation/screens/pin_create_screen.dart';
import 'package:henshin/features/setting/presentation/screens/pin_verify_screen.dart';
import 'package:henshin/features/setting/presentation/screens/setting_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_history_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/cashier_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: PageRoutes.dashboard,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScreen(navigationShell: navigationShell);
      },
      branches: [
        // branch dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.dashboard,
              name: PageRoutes.dashboardName,
              builder: (context, state) => DashboardScreen(),
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

        // brach setting
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: PageRoutes.setting,
              name: PageRoutes.settingName,
              builder: (context, state) => SettingScreen(),
            ),
          ],
        ),
      ],
    ),

    // branch dll.
    // 
    // Kasir: keranjang + bayar. Scanner di-push dari dalam sini dengan
    // BlocProvider.value, bukan rute sendiri, karena butuh CartBloc yang sama.
    GoRoute(
      path: PageRoutes.mulaiTransaksi,
      name: PageRoutes.mulaiTransaksiName,
      builder: (context, state) => const CashierScreen(),
    ),


    GoRoute(
      path: PageRoutes.perluRestok,
      name: PageRoutes.perluRestokName,
      builder: (context, state) => const LowStockScreen(),
    ),

    GoRoute(
      path: PageRoutes.aturPin,
      name: PageRoutes.aturPinName,
      builder: (context, state) => const PinCreateScreen(),
    ),

    // dipanggil lewat PinGate.require, bukan langsung
    GoRoute(
      path: PageRoutes.verifikasiPin,
      name: PageRoutes.verifikasiPinName,
      builder: (context, state) =>
          PinVerifyScreen(reason: state.uri.queryParameters['reason']),
    ),
  ],
);

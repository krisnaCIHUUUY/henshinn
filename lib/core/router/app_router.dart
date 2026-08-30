import 'package:go_router/go_router.dart';
import 'package:henshin/app.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';
import 'package:henshin/features/setting/presentation/screens/setting_screen.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_history_screen.dart';

// bikin app routernya nanti di lanjutin

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
  ],
);

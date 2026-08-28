import 'package:go_router/go_router.dart';
import 'package:henshin/app.dart';

// bikin app routernya nanti di lanjutin

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScreen();
      },
      branches: [StatefulShellBranch(routes: [])],
    ),
  ],
);

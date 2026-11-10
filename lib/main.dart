import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/router/app_router.dart';
import 'package:henshin/core/theme/app_theme.dart';
import 'package:henshin/features/product/presentation/bloc/product_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/injection_container.dart';

void main() {
  initDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductBloc>(create: (_) => sl<ProductBloc>()),
        // CartBloc sengaja di atas router: Kasir sekarang tab, jadi kalau
        // keranjang dibuat di dalam layarnya, pindah tab di tengah transaksi
        // mengosongkannya (ADR-048). Jangan turunkan ke CashierScreen.
        BlocProvider<CartBloc>(create: (_) => sl<CartBloc>()),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
        title: 'Henshin',
        theme: AppTheme.light,
      ),
    );
  }
}

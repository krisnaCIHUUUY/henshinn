import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/theme/app_text_style.dart';

// import 'package:henshin/features/product/presentation/screens/product_list_screen.dart';

class AppScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const AppScreen({super.key, required this.navigationShell});

  void _onTabTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Text(
            'Henshin',
            style: AppTextStyle.headlineMd.copyWith(color: AppColor.primary),
          ),
        ),
      ),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTabTap,
        currentIndex: navigationShell.currentIndex,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Produk',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
        ],
      ),
    );
  }
}

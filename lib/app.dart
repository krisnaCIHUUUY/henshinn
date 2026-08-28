import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_text_style.dart';

class AppScreen extends StatelessWidget {
  const AppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: const Text('Henshin', style: AppTextStyle.headlineLg),
        ),
      ),
      body: const Center(child: Text('Welcome to Henshin!')),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (value) {
          // implementasi navigasi pake go router
        },
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

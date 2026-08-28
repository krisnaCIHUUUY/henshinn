import 'package:flutter/material.dart';
import 'package:henshin/app.dart';
import 'package:henshin/core/theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Henshin',
      theme: AppTheme.light,
      home: const AppScreen(),
    );
  }
}

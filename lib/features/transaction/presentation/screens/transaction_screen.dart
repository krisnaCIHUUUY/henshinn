import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/utils/page_routes.dart';

class TransactionScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go(PageRoutes.dashboard);
          },
          child: Text("balik"),
        ),
      ),
    );
  }
}

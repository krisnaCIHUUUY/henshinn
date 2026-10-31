import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/injection_container.dart';

/// Pintu PIN untuk aksi sensitif: void, restore, ubah harga/modal, lihat laba
/// (PRD §1.6). Dipasang ke aksi-aksi itu di langkah masing-masing.
///
/// Pola pakai:
/// ```dart
/// if (!await PinGate.require(context, reason: 'Diperlukan untuk void')) return;
/// ```
class PinGate {
  const PinGate._();

  /// `true` hanya kalau pemilik memasukkan PIN yang benar.
  ///
  /// Kalau PIN belum pernah dibuat, gate ini **menolak** dan mengarahkan ke
  /// Pengaturan — bukan menawarkan buat PIN di tempat — supaya orang lain tidak
  /// bisa lewat gate dengan cara membuat PIN pertama sendiri.
  static Future<bool> require(
    BuildContext context, {
    required String reason,
  }) async {
    final hasPin = (await sl<PinRepository>().hasPin()).getOrElse(() => false);

    if (!context.mounted) return false;

    if (!hasPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buat PIN dulu di Pengaturan sebelum memakai fitur ini'),
        ),
      );
      return false;
    }

    final verified = await context.push<bool>(
      Uri(
        path: PageRoutes.verifikasiPin,
        queryParameters: {'reason': reason},
      ).toString(),
    );
    return verified ?? false;
  }
}

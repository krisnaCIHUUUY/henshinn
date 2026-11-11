import 'package:flutter/material.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/widgets/pin_verify_sheet.dart';
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
    if (!await hasPinOrWarn(context) || !context.mounted) return false;

    // Sheet, bukan rute: konteks di belakangnya tetap terlihat (ADR-049).
    // isScrollControlled supaya keypad tidak terpotong di HP pendek.
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PinVerifySheet(reason: reason),
    );
    return verified ?? false;
  }

  /// `true` kalau PIN sudah pernah dibuat; kalau belum, pesannya ditampilkan
  /// dan pemanggil harus berhenti.
  ///
  /// Terbuka sendiri karena sheet void memasang keypad-nya sendiri (satu sheet
  /// untuk alasan + PIN, ADR-054) tapi tetap harus menolak di pintu yang sama —
  /// bukan dengan salinan pemeriksaan ini.
  static Future<bool> hasPinOrWarn(BuildContext context) async {
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
    return true;
  }
}

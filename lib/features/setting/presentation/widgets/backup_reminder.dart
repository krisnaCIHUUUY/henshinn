import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';

/// Pengingat backup >7 hari (langkah 13). Sengaja tidak bisa ditutup: satu-satunya
/// cara menghilangkannya adalah benar-benar backup.
///
/// Tidak punya tombol sendiri sejak D8. Rumahnya sekarang Pengaturan (dulu
/// Dasbor, ADR-047), dan di sana tombol "Buat backup" ada tepat di kartu
/// bawahnya — dua tombol dengan aksi identik berjarak 24 px hanya membuat
/// pemilik ragu mana yang benar.
class BackupReminder extends StatelessWidget {
  const BackupReminder({super.key, required this.store});

  final StoreInfo store;

  @override
  Widget build(BuildContext context) {
    final days = store.daysSinceBackup(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: AppColor.warningSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: AppColor.warning),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  days == null
                      ? 'Data belum pernah di-backup'
                      : 'Backup terakhir $days hari lalu',
                  style: AppTextStyle.bodyStrong.copyWith(
                    color: AppColor.warning,
                  ),
                ),
                Text(
                  'Buat backup sekarang supaya data toko aman kalau HP rusak '
                  'atau hilang.',
                  style: AppTextStyle.label.copyWith(color: AppColor.warning),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/setting/domain/entities/store_info.dart';
import 'package:henshin/features/setting/presentation/backup_action.dart';

/// Pengingat backup >7 hari (langkah 13). Sengaja tidak bisa ditutup: satu-satunya
/// cara menghilangkannya adalah benar-benar backup.
class BackupReminder extends StatelessWidget {
  const BackupReminder({super.key, required this.store, required this.onDone});

  final StoreInfo store;

  /// Dipanggil setelah backup berhasil, supaya pemanggil memuat ulang
  /// `lastBackupAt` dan banner ini hilang.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final days = store.daysSinceBackup(DateTime.now());

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColor.warningSoft,
        borderRadius: AppRadius.lgAll,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.backup_outlined,
                size: 20,
                color: AppColor.warning,
              ),
              const SizedBox(width: AppSpacing.s2),
              Expanded(
                child: Text(
                  days == null
                      ? 'Data belum pernah di-backup'
                      : 'Backup terakhir $days hari lalu',
                  style: AppTextStyle.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColor.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            'Kalau HP ini hilang atau rusak, data penjualan ikut hilang.',
            style: AppTextStyle.label.copyWith(
              color: AppColor.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: () async {
                if (await BackupAction.run(context)) onDone();
              },
              child: const Text('Backup sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}

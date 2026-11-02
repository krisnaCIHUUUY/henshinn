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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColor.errorContainer,
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
                color: AppColor.onErrorContainer,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  days == null
                      ? 'Data belum pernah di-backup'
                      : 'Backup terakhir $days hari lalu',
                  style: AppTextStyle.bodyMd.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColor.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Kalau HP ini hilang atau rusak, data penjualan ikut hilang.',
            style: AppTextStyle.labelSm.copyWith(
              color: AppColor.onErrorContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
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

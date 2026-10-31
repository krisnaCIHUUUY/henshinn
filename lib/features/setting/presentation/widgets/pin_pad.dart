import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_radius.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';

/// Keypad angka + titik indikator. Input-nya dipegang pemanggil supaya layar
/// buat-PIN bisa menahan dua tahap (isi lalu ulangi) tanpa state ganda.
class PinPad extends StatelessWidget {
  const PinPad({
    super.key,
    required this.title,
    required this.subtitle,
    required this.filled,
    required this.onDigit,
    required this.onBackspace,
    this.errorText,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final int filled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: AppTextStyle.headlineLg.copyWith(color: AppColor.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle,
          style: AppTextStyle.bodyMd.copyWith(color: AppColor.outline),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _Dots(filled: filled, isError: errorText != null),
        const SizedBox(height: AppSpacing.md),
        // Ruang teks error selalu disisakan supaya keypad tidak melompat.
        SizedBox(
          height: 40,
          child: errorText == null
              ? null
              : Text(
                  errorText!,
                  style: AppTextStyle.bodyMd.copyWith(color: AppColor.error),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Keypad(
          enabled: enabled,
          onDigit: onDigit,
          onBackspace: onBackspace,
        ),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.filled, required this.isError});

  final int filled;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(PinRepository.pinLength, (index) {
        final isFilled = index < filled;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (isError ? AppColor.error : AppColor.onSurface)
                : Colors.transparent,
            border: Border.all(
              color: isError ? AppColor.error : AppColor.outlineVariant,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<'],
        ])
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final key in row)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: _Key(
                    label: key,
                    enabled: enabled && key.isNotEmpty,
                    onTap: key == '<' ? onBackspace : () => onDigit(key),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) {
      return const SizedBox(width: 72, height: 64);
    }

    return SizedBox(
      width: 72,
      height: 64,
      child: Material(
        color: AppColor.surfaceContainerLow,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.mdAll,
          child: Center(
            child: label == '<'
                ? Icon(
                    Icons.backspace_outlined,
                    color: enabled ? AppColor.onSurface : AppColor.outline,
                  )
                : Text(
                    label,
                    style: AppTextStyle.headlineLg.copyWith(
                      color: enabled ? AppColor.onSurface : AppColor.outline,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

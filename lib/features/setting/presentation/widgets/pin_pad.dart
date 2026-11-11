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
          style: AppTextStyle.heading.copyWith(color: AppColor.ink),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s2),
        Text(
          subtitle,
          style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.s6),
        _Dots(filled: filled, isError: errorText != null),
        const SizedBox(height: AppSpacing.s4),
        // Ruang teks error selalu disisakan supaya keypad tidak melompat.
        SizedBox(
          height: 40,
          child: errorText == null
              ? null
              : Text(
                  errorText!,
                  style: AppTextStyle.body.copyWith(color: AppColor.danger),
                  textAlign: TextAlign.center,
                ),
        ),
        const SizedBox(height: AppSpacing.s6),
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
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s2),
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (isError ? AppColor.danger : AppColor.ink)
                : Colors.transparent,
            border: Border.all(
              color: isError ? AppColor.danger : AppColor.lineStrong,
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
                  padding: const EdgeInsets.all(AppSpacing.s2),
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
        color: AppColor.surfaceMuted,
        borderRadius: AppRadius.mdAll,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: AppRadius.mdAll,
          child: Center(
            child: label == '<'
                ? Icon(
                    Icons.backspace_outlined,
                    color: enabled ? AppColor.ink : AppColor.inkMuted,
                  )
                : Text(
                    label,
                    style: AppTextStyle.title.copyWith(
                      color: enabled ? AppColor.ink : AppColor.inkMuted,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

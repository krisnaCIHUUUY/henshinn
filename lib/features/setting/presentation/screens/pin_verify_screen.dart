import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_bloc.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_event.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_state.dart';
import 'package:henshin/features/setting/presentation/widgets/pin_pad.dart';
import 'package:henshin/injection_container.dart';

/// Pop `true` kalau PIN benar, `false`/null kalau dibatalkan.
/// Jangan dipanggil langsung — pakai `PinGate.require` supaya kasus
/// "PIN belum dibuat" tertangani.
class PinVerifyScreen extends StatelessWidget {
  const PinVerifyScreen({super.key, this.reason});

  /// Ditampilkan sebagai subtitle, mis. "Diperlukan untuk void transaksi".
  final String? reason;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PinBloc>()..add(const PinEvent.statusRequested()),
      child: _PinVerifyView(reason: reason),
    );
  }
}

class _PinVerifyView extends StatefulWidget {
  const _PinVerifyView({this.reason});

  final String? reason;

  @override
  State<_PinVerifyView> createState() => _PinVerifyViewState();
}

class _PinVerifyViewState extends State<_PinVerifyView> {
  static const _length = PinRepository.pinLength;

  String _input = '';
  Timer? _unlockTimer;

  @override
  void dispose() {
    _unlockTimer?.cancel();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_input.length >= _length) return;
    setState(() => _input += digit);
    if (_input.length == _length) {
      context.read<PinBloc>().add(PinEvent.submitted(_input));
    }
  }

  void _onBackspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  /// Satu timer sampai masa tunggu habis, lalu keypad hidup lagi.
  /// shortcut: tidak ada hitungan detik yang berjalan di layar — pesan sudah
  /// menyebut durasinya. Tambahkan Timer.periodic kalau pemilik memintanya.
  void _scheduleUnlock(Duration remaining) {
    _unlockTimer?.cancel();
    _unlockTimer = Timer(remaining, () {
      if (mounted) {
        context.read<PinBloc>().add(const PinEvent.statusRequested());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: const Text('Masukkan PIN'),
      ),
      body: SafeArea(
        child: BlocConsumer<PinBloc, PinState>(
          listener: (context, state) {
            switch (state.status) {
              case PinStatus.success:
                Navigator.of(context).pop(true);
              case PinStatus.wrong:
                setState(() => _input = '');
              case PinStatus.locked:
                setState(() => _input = '');
                final remaining = state.lockedFor;
                if (remaining != null) _scheduleUnlock(remaining);
              case PinStatus.failure:
                setState(() => _input = '');
              case PinStatus.initial:
              case PinStatus.loading:
                break;
            }
          },
          builder: (context, state) {
            final isLocked = state.status == PinStatus.locked;
            final isBusy = state.status == PinStatus.loading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PinPad(
                title: 'Masukkan PIN',
                subtitle: widget.reason ?? 'PIN pemilik diperlukan',
                filled: _input.length,
                errorText: state.errorMessage.isEmpty
                    ? null
                    : state.errorMessage,
                enabled: !isLocked && !isBusy,
                onDigit: _onDigit,
                onBackspace: _onBackspace,
              ),
            );
          },
        ),
      ),
    );
  }
}

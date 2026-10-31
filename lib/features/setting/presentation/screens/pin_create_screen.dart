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

/// Dua tahap: isi PIN lalu ulangi. PIN hanya tersimpan kalau keduanya sama.
class PinCreateScreen extends StatelessWidget {
  const PinCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PinBloc>()..add(const PinEvent.statusRequested()),
      child: const _PinCreateView(),
    );
  }
}

class _PinCreateView extends StatefulWidget {
  const _PinCreateView();

  @override
  State<_PinCreateView> createState() => _PinCreateViewState();
}

class _PinCreateViewState extends State<_PinCreateView> {
  static const _length = PinRepository.pinLength;

  String _first = '';
  String _repeat = '';
  String? _error;

  bool get _isRepeatStage => _first.length == _length;
  String get _current => _isRepeatStage ? _repeat : _first;

  void _onDigit(String digit) {
    if (_current.length >= _length) return;
    setState(() {
      _error = null;
      if (_isRepeatStage) {
        _repeat += digit;
      } else {
        _first += digit;
      }
    });

    if (_isRepeatStage && _repeat.length == _length) _submit();
  }

  void _onBackspace() {
    setState(() {
      _error = null;
      if (_isRepeatStage && _repeat.isNotEmpty) {
        _repeat = _repeat.substring(0, _repeat.length - 1);
      } else if (!_isRepeatStage && _first.isNotEmpty) {
        _first = _first.substring(0, _first.length - 1);
      } else if (_isRepeatStage) {
        // tahap ulangi tapi kosong: kembali ke tahap pertama
        _first = _first.substring(0, _first.length - 1);
      }
    });
  }

  void _submit() {
    if (_first != _repeat) {
      setState(() {
        _error = 'PIN tidak sama, coba lagi';
        _first = '';
        _repeat = '';
      });
      return;
    }
    context.read<PinBloc>().add(PinEvent.created(_first));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.surface,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        title: const Text('Atur PIN'),
      ),
      body: SafeArea(
        child: BlocConsumer<PinBloc, PinState>(
          listener: (context, state) {
            if (state.status == PinStatus.success) {
              Navigator.of(context).pop(true);
              return;
            }
            if (state.status == PinStatus.failure) {
              setState(() {
                _error = state.errorMessage;
                _first = '';
                _repeat = '';
              });
            }
          },
          builder: (context, state) {
            final isSaving = state.status == PinStatus.loading;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: PinPad(
                title: _isRepeatStage ? 'Ulangi PIN' : 'Buat PIN',
                subtitle: _isRepeatStage
                    ? 'Masukkan ulang $_length angka yang sama'
                    : 'PIN melindungi void, restore, ubah harga, dan laba',
                filled: _current.length,
                errorText: _error,
                enabled: !isSaving,
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

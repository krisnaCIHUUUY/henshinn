import 'package:freezed_annotation/freezed_annotation.dart';

part 'pin_state.freezed.dart';

enum PinStatus {
  initial,
  loading,

  /// PIN benar, atau PIN baru berhasil disimpan.
  success,

  /// PIN salah tapi masih boleh mencoba.
  wrong,

  /// Kena jeda karena terlalu banyak salah — lihat `lockedFor`.
  locked,
  failure,
}

@freezed
abstract class PinState with _$PinState {
  const factory PinState({
    @Default(PinStatus.initial) PinStatus status,
    @Default(false) bool hasPin,
    Duration? lockedFor,
    @Default('') String errorMessage,
  }) = _PinState;
}

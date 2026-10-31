import 'package:freezed_annotation/freezed_annotation.dart';

part 'pin_event.freezed.dart';

@freezed
class PinEvent with _$PinEvent {
  /// Dipanggil saat layar dibuka: cek PIN sudah ada + sisa masa tunggu.
  const factory PinEvent.statusRequested() = PinStatusRequested;
  const factory PinEvent.created(String pin) = PinCreated;
  const factory PinEvent.submitted(String pin) = PinSubmitted;
}

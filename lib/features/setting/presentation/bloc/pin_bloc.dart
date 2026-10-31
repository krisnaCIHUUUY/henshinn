import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/domain/usecases/has_pin.dart';
import 'package:henshin/features/setting/domain/usecases/set_pin.dart';
import 'package:henshin/features/setting/domain/usecases/verify_pin.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_event.dart';
import 'package:henshin/features/setting/presentation/bloc/pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  final PinRepository _repository;
  final HasPin _hasPin;
  final SetPin _setPin;
  final VerifyPin _verifyPin;

  PinBloc({
    required this._repository,
    required this._hasPin,
    required this._setPin,
    required this._verifyPin,
  }) : super(const PinState()) {
    on<PinStatusRequested>(_onStatusRequested);
    on<PinCreated>(_onCreated);
    on<PinSubmitted>(_onSubmitted);
  }

  Future<void> _onStatusRequested(
    PinStatusRequested event,
    Emitter<PinState> emit,
  ) async {
    final result = await _hasPin();

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: PinStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (hasPin) async {
        // Masa tunggu yang masih berjalan tetap terlihat walau layar ditutup
        // lalu dibuka lagi. Penegakannya ada di repository, bukan di layar.
        final lockout =
            (await _repository.lockoutRemaining()).getOrElse(() => null);

        emit(
          state.copyWith(
            status: lockout == null ? PinStatus.initial : PinStatus.locked,
            hasPin: hasPin,
            lockedFor: lockout,
            errorMessage: lockout == null ? '' : 'Tunggu sebelum mencoba lagi',
          ),
        );
      },
    );
  }

  Future<void> _onCreated(PinCreated event, Emitter<PinState> emit) async {
    emit(state.copyWith(status: PinStatus.loading, errorMessage: ''));

    final result = await _setPin(event.pin);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PinStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(state.copyWith(status: PinStatus.success, hasPin: true)),
    );
  }

  Future<void> _onSubmitted(PinSubmitted event, Emitter<PinState> emit) async {
    emit(state.copyWith(status: PinStatus.loading, errorMessage: ''));

    final result = await _verifyPin(event.pin);
    result.fold(
      (failure) => emit(
        failure is PinLockedFailure
            ? state.copyWith(
                status: PinStatus.locked,
                lockedFor: failure.remaining,
                errorMessage: failure.message,
              )
            : state.copyWith(
                status: PinStatus.failure,
                errorMessage: failure.message,
              ),
      ),
      (isCorrect) => emit(
        isCorrect
            ? state.copyWith(status: PinStatus.success, lockedFor: null)
            : state.copyWith(
                status: PinStatus.wrong,
                errorMessage: 'PIN salah',
              ),
      ),
    );
  }
}

import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';

class SetPin {
  final PinRepository repository;

  SetPin(this.repository);

  Future<Either<Failure, void>> call(String pin) {
    return repository.setPin(pin);
  }
}

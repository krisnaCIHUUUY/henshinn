import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';

class VerifyPin {
  final PinRepository repository;

  VerifyPin(this.repository);

  Future<Either<Failure, bool>> call(String pin) {
    return repository.verifyPin(pin);
  }
}

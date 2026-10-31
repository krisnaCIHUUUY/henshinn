import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';

class HasPin {
  final PinRepository repository;

  HasPin(this.repository);

  Future<Either<Failure, bool>> call() {
    return repository.hasPin();
  }
}

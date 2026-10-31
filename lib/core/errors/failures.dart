import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Terlalu banyak PIN salah — pemanggil harus menunggu `remaining` dulu.
class PinLockedFailure extends Failure {
  final Duration remaining;

  const PinLockedFailure(super.message, this.remaining);

  @override
  List<Object?> get props => [message, remaining];
}

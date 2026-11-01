import 'package:dartz/dartz.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';

abstract class ReportRepository {
  /// Angka satu periode preset, tanpa transaksi void.
  Future<Either<Failure, SalesReport>> getReport(ReportPeriod period);
}

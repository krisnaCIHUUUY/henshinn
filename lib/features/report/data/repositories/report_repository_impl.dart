import 'package:dartz/dartz.dart';
import 'package:henshin/core/database/dao/report_dao.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/features/report/domain/entities/sales_report.dart';
import 'package:henshin/features/report/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._dao, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final ReportDao _dao;

  /// Disuntik supaya tes bisa memilih "sekarang" tanpa menunggu tengah malam.
  final DateTime Function() _now;

  @override
  Future<Either<Failure, SalesReport>> getReport(ReportPeriod period) async {
    try {
      final (start, end) = period.rangeFrom(_now());

      final headers = await _dao.getCompletedTransactions(start, end);
      final (profit, items) = await _dao.getProfitAndItemCount(start, end);
      final bestSellers = await _dao.getBestSellers(start: start, end: end);

      return Right(
        SalesReport(
          period: period,
          revenue: headers.fold(0, (sum, t) => sum + t.total),
          grossProfit: profit,
          transactionCount: headers.length,
          itemCount: items,
          bestSellers: [
            for (final (name, qty) in bestSellers)
              BestSeller(name: name, qtySold: qty),
          ],
          daily: _daily(headers.map((t) => (t.date, t.total)), start, period),
        ),
      );
    } catch (e) {
      return Left(DatabaseFailure('Gagal menyusun laporan: $e'));
    }
  }

  /// Omzet per hari kalender lokal, satu entri untuk **tiap** hari dalam
  /// periode termasuk yang kosong.
  List<DailyRevenue> _daily(
    Iterable<(DateTime date, int total)> sales,
    DateTime start,
    ReportPeriod period,
  ) {
    final buckets = <DateTime, int>{
      for (var i = 0; i < period.days; i++)
        DateTime(start.year, start.month, start.day + i): 0,
    };

    for (final (date, total) in sales) {
      final day = DateTime(date.year, date.month, date.day);
      // Baris di luar rentang tidak mungkin ada (query sudah menyaring), tapi
      // jam musim/DST bisa menggeser kunci — dilewati daripada menambah hari.
      if (buckets.containsKey(day)) buckets[day] = buckets[day]! + total;
    }

    return [
      for (final entry in buckets.entries)
        DailyRevenue(date: entry.key, revenue: entry.value),
    ];
  }
}

import 'package:flutter/material.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/core/theme/app_spacing.dart';
import 'package:henshin/core/theme/app_text_style.dart';
import 'package:henshin/core/utils/currency_formatter.dart';
import 'package:henshin/core/widgets/app_badge.dart';
import 'package:henshin/core/widgets/app_card.dart';
import 'package:henshin/core/widgets/app_chip.dart';
import 'package:henshin/core/widgets/section_header.dart';
import 'package:henshin/features/transaction/domain/entities/transaction_summary.dart';
import 'package:henshin/features/transaction/domain/repositories/transaction_repository.dart';
import 'package:henshin/features/transaction/presentation/screens/transaction_detail_screen.dart';
import 'package:henshin/injection_container.dart';
import 'package:intl/intl.dart';

/// Rentang yang bisa dipilih di Riwayat. `pickedDate` bukan "rentang bebas"
/// (PRD §3.2 masih di luar lingkup) — hanya satu hari kalender.
enum HistoryRange { today, yesterday, week, pickedDate }

/// Batas bawah dan atas untuk satu chip rentang, **inklusif** keduanya.
///
/// Hari kalender penuh, bukan 24 jam ke belakang: pemilik menghitung harinya
/// dari tengah malam, dan "Kemarin" tanpa batas atas akan ikut memuat hari ini.
/// Aturan yang sama dengan `ReportPeriod.rangeFrom`.
///
/// Fungsi lepas supaya bisa diuji `test()` biasa (ADR-012).
(DateTime, DateTime) historyRange(
  HistoryRange range,
  DateTime now, {
  DateTime? picked,
}) {
  DateTime endOf(DateTime day) => day
      .add(const Duration(days: 1))
      .subtract(const Duration(microseconds: 1));

  final today = DateTime(now.year, now.month, now.day);

  return switch (range) {
    HistoryRange.today => (today, endOf(today)),
    HistoryRange.yesterday => (
      today.subtract(const Duration(days: 1)),
      endOf(today.subtract(const Duration(days: 1))),
    ),
    HistoryRange.week => (today.subtract(const Duration(days: 6)), endOf(today)),
    // Tanpa tanggal terpilih chip ini belum bisa menyaring apa pun, jadi
    // jatuh kembali ke hari ini daripada memunculkan rentang kosong.
    HistoryRange.pickedDate when picked == null => (today, endOf(today)),
    HistoryRange.pickedDate => (
      DateTime(picked!.year, picked.month, picked.day),
      endOf(DateTime(picked.year, picked.month, picked.day)),
    ),
  };
}

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  HistoryRange _range = HistoryRange.today;
  DateTime? _picked;

  // Stream disimpan, bukan dibuat di build(): tiap build baru akan
  // berlangganan ulang dan membuat list berkedip ke spinner.
  late Stream<List<TransactionSummary>> _stream = _watch();

  Stream<List<TransactionSummary>> _watch() {
    final (since, until) = historyRange(
      _range,
      DateTime.now(),
      picked: _picked,
    );
    return sl<TransactionRepository>().watchHistory(
      since: since,
      until: until,
    );
  }

  void _select(HistoryRange range, {DateTime? picked}) {
    setState(() {
      _range = range;
      if (picked != null) _picked = picked;
      _stream = _watch();
    });
  }

  /// `firstDate` 2020: tidak ada transaksi yang lebih tua dari aplikasinya,
  /// dan membiarkannya terbuka membuat kalender bisa digulir tanpa ujung.
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _picked ?? now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: 'Pilih tanggal transaksi',
    );
    if (chosen == null || !mounted) return;
    _select(HistoryRange.pickedDate, picked: chosen);
  }

  /// Judul bagian. Tanggal terpilih ditulis lengkap supaya pemilik tahu
  /// rentang mana yang sedang dilihat setelah kalender tertutup.
  String get _rangeLabel => switch (_range) {
    HistoryRange.today => 'Hari ini',
    HistoryRange.yesterday => 'Kemarin',
    HistoryRange.week => '7 hari',
    HistoryRange.pickedDate => _picked == null
        ? 'Hari ini'
        : DateFormat('dd/MM/yyyy').format(_picked!),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.bg,
      // Tanpa aksi: ikon "Cari transaksi" di mockup tidak dibangun (pencarian
      // transaksi bukan lingkup PRD) dan ikon ekspor yang mati sudah dihapus
      // (keputusan pemilik 6).
      appBar: AppBar(
        title: Text(
          'Riwayat',
          style: AppTextStyle.title.copyWith(color: AppColor.ink),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            ChipRow(
              children: [
                AppChip(
                  label: 'Hari ini',
                  selected: _range == HistoryRange.today,
                  onTap: () => _select(HistoryRange.today),
                ),
                AppChip(
                  label: 'Kemarin',
                  selected: _range == HistoryRange.yesterday,
                  onTap: () => _select(HistoryRange.yesterday),
                ),
                AppChip(
                  label: '7 hari',
                  selected: _range == HistoryRange.week,
                  onTap: () => _select(HistoryRange.week),
                ),
                AppChip(
                  label: _range == HistoryRange.pickedDate && _picked != null
                      ? DateFormat('dd/MM').format(_picked!)
                      : 'Pilih tanggal',
                  selected: _range == HistoryRange.pickedDate,
                  onTap: _pickDate,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Expanded(
              child: StreamBuilder<List<TransactionSummary>>(
                // Stream Drift: setelah void, list menyegarkan dirinya sendiri.
                stream: _stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _EmptyOrError(
                      message: 'Gagal memuat riwayat: ${snapshot.error}',
                    );
                  }
                  final items = snapshot.data;
                  if (items == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (items.isEmpty) {
                    return const _EmptyOrError(
                      message: 'Belum ada transaksi di periode ini',
                    );
                  }

                  final voided = items.where((i) => i.isVoided).length;

                  return ListView(
                    padding: const EdgeInsets.only(bottom: AppSpacing.s6),
                    children: [
                      SectionHeader(
                        title: '$_rangeLabel · ${items.length} transaksi',
                        trailing: voided == 0
                            ? null
                            : Text(
                                '$voided void',
                                style: AppTextStyle.label.copyWith(
                                  color: AppColor.inkMuted,
                                ),
                              ),
                      ),
                      AppCard(
                        children: [
                          for (final item in items)
                            _TransactionRow(
                              item: item,
                              onTap: () => Navigator.of(context).push<void>(
                                MaterialPageRoute(
                                  builder: (_) => TransactionDetailScreen(
                                    transactionId: item.id,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s6),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyle.body.copyWith(color: AppColor.inkMuted),
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item, required this.onTap});

  final TransactionSummary item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = formatRupiah(item.total);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: AppSpacing.rowMin),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s4,
          AppSpacing.s2,
          AppSpacing.s2,
          AppSpacing.s2,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    // Format angka, bukan nama bulan: nama bulan lokal butuh
                    // data locale intl yang belum diinisialisasi di app ini.
                    '#${item.id} · ${DateFormat('dd/MM HH.mm').format(item.dateTime)}',
                    style: AppTextStyle.body.copyWith(color: AppColor.ink),
                  ),
                  Text(
                    '${item.itemCount} item',
                    style: AppTextStyle.label.copyWith(
                      color: AppColor.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.s2),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  total,
                  style: AppTextStyle.bodyStrong.copyWith(
                    color: item.isVoided ? AppColor.inkMuted : AppColor.ink,
                    // Dicoret, bukan hanya diredam: angka yang di-void tidak
                    // boleh ikut dijumlahkan pemilik saat membaca daftar ini.
                    decoration: item.isVoided
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.s1),
                AppBadge(
                  label: item.isVoided ? 'Void' : 'Selesai',
                  tone: item.isVoided ? BadgeTone.danger : BadgeTone.success,
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: AppColor.inkMuted),
          ],
        ),
      ),
    );
  }
}

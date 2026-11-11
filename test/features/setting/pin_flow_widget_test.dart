import 'package:flutter/material.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/screens/pin_create_screen.dart';
import 'package:henshin/features/setting/presentation/pin_gate.dart';
import 'package:henshin/injection_container.dart';

import 'fake_secure_storage.dart';

void main() {
  const pin = '135790';
  late FakeSecureStorage fake;

  setUp(() {
    fake = FakeSecureStorage();
    FlutterSecureStoragePlatform.instance = fake;
    initDependencies();
  });

  tearDown(sl.reset);

  /// PBKDF2 jalan di isolate terpisah dengan waktu nyata, sementara
  /// `testWidgets` memakai waktu palsu — `pumpAndSettle` saja tidak pernah
  /// menunggunya. Jadi hasilnya ditunggu dengan waktu nyata **sampai UI-nya
  /// benar-benar berubah**, bukan dengan satu delay tetap: delay tetap pernah
  /// kehabisan waktu saat suite penuh jalan paralel dan mesinnya sibuk.
  Future<void> waitUntil(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 60; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
      if (done()) return;
    }
    fail('kondisi yang ditunggu tidak pernah terpenuhi dalam 12 detik');
  }

  /// Menekan tombol keypad sungguhan, bukan memanggil bloc langsung.
  Future<void> tapPin(
    WidgetTester tester,
    String digits, {
    required bool Function() until,
  }) async {
    for (final digit in digits.split('')) {
      // find.text cocok persis, jadi tidak tertukar dengan angka di subtitle.
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await waitUntil(tester, until);
  }

  bool visible(String text) => find.text(text).evaluate().isNotEmpty;

  /// Verifikasi dibuka lewat `PinGate.require` — jalur yang sungguhan dipakai
  /// empat aksi ber-PIN, dan sejak D3 isinya sheet, bukan rute.
  Future<void> openPinGate(WidgetTester tester, String reason) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => PinGate.require(context, reason: reason),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  Future<void> pushScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => screen),
            ),
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
  }

  testWidgets('buat PIN lalu verifikasi: benar lolos, salah ditolak', (
    tester,
  ) async {
    // ===== buat PIN (isi lalu ulangi) =====
    await pushScreen(tester, const PinCreateScreen());
    expect(find.text('Buat PIN'), findsOneWidget);

    await tapPin(tester, pin, until: () => visible('Ulangi PIN'));
    await tapPin(
      tester,
      pin,
      until: () => fake.store.containsKey('pin_v1'),
    );

    expect((await sl<PinRepository>().hasPin()).getOrElse(() => false), isTrue);

    // ===== app ditutup lalu dibuka lagi =====
    await sl.reset();
    initDependencies();

    // ===== PIN salah: sheet tetap terbuka, muncul pesan =====
    await openPinGate(tester, 'Uji coba');
    await tapPin(tester, '000000', until: () => visible('PIN salah'));
    expect(find.text('Masukkan PIN'), findsWidgets);

    // ===== PIN benar: sheet tertutup =====
    await tapPin(tester, pin, until: () => !visible('Uji coba'));
  });

  testWidgets('PIN ulangan yang tidak sama tidak tersimpan', (tester) async {
    await pushScreen(tester, const PinCreateScreen());

    await tapPin(tester, pin, until: () => visible('Ulangi PIN'));
    await tapPin(
      tester,
      '999999',
      until: () => visible('PIN tidak sama, coba lagi'),
    );

    expect(fake.store.containsKey('pin_v1'), isFalse);
  });
}

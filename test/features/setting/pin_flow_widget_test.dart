import 'package:flutter/material.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:henshin/features/setting/domain/repositories/pin_repository.dart';
import 'package:henshin/features/setting/presentation/screens/pin_create_screen.dart';
import 'package:henshin/features/setting/presentation/screens/pin_verify_screen.dart';
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

  /// Menekan tombol keypad sungguhan, bukan memanggil bloc langsung.
  Future<void> tapPin(WidgetTester tester, String digits) async {
    for (final digit in digits.split('')) {
      // find.text cocok persis, jadi tidak tertukar dengan angka di subtitle.
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    // PBKDF2 jalan di isolate terpisah dengan waktu nyata; `pumpAndSettle`
    // hanya memajukan waktu palsu, jadi isolate-nya harus ditunggu via
    // runAsync. Angkanya dilebihkan supaya tidak rapuh di mesin lambat.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pumpAndSettle();
  }

  Future<bool?> pushScreen(WidgetTester tester, Widget screen) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => screen),
              );
            },
            child: const Text('buka'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pumpAndSettle();
    return result;
  }

  testWidgets('buat PIN lalu verifikasi: benar lolos, salah ditolak', (
    tester,
  ) async {
    // ===== buat PIN (isi lalu ulangi) =====
    await pushScreen(tester, const PinCreateScreen());
    expect(find.text('Buat PIN'), findsOneWidget);

    await tapPin(tester, pin);
    expect(find.text('Ulangi PIN'), findsOneWidget);
    await tapPin(tester, pin);

    expect(fake.store.containsKey('pin_v1'), isTrue);
    expect((await sl<PinRepository>().hasPin()).getOrElse(() => false), isTrue);

    // ===== app ditutup lalu dibuka lagi =====
    await sl.reset();
    initDependencies();

    // ===== PIN salah: tetap di layar, muncul pesan =====
    await pushScreen(tester, const PinVerifyScreen(reason: 'Uji coba'));
    await tapPin(tester, '000000');
    expect(find.text('PIN salah'), findsOneWidget);
    expect(find.text('Masukkan PIN'), findsWidgets);

    // ===== PIN benar: layar tertutup =====
    await tapPin(tester, pin);
    expect(find.text('Uji coba'), findsNothing);
  });

  testWidgets('PIN ulangan yang tidak sama tidak tersimpan', (tester) async {
    await pushScreen(tester, const PinCreateScreen());

    await tapPin(tester, pin);
    await tapPin(tester, '999999');

    expect(find.text('PIN tidak sama, coba lagi'), findsOneWidget);
    expect(fake.store.containsKey('pin_v1'), isFalse);
  });
}

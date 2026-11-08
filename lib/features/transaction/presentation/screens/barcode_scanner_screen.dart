import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:henshin/core/errors/failures.dart';
import 'package:henshin/core/theme/app_color.dart';
import 'package:henshin/features/product/domain/entities/product.dart';
import 'package:henshin/features/product/domain/usecases/get_product_by_barcode.dart';
import 'package:henshin/features/product/presentation/screens/product_form_screen.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_bloc.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_event.dart';
import 'package:henshin/features/transaction/presentation/bloc/cart_state.dart';
import 'package:henshin/injection_container.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

/// Scan berturut: kamera tetap hidup, tiap barcode yang dikenali langsung
/// masuk keranjang. Harus di-push dengan `BlocProvider.value` dari kasir
/// supaya memakai `CartBloc` yang sama — bukan rute top-level.
class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  /// autoStart false: controller dinyalakan sendiri di initState sesuai pola
  /// yang dianjurkan mobile_scanner v7.
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.qrCode,
    ],
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    returnImage: false,
  );

  StreamSubscription<BarcodeCapture>? _subscription;

  /// Jeda sebelum barcode yang sama diterima lagi. Bukan blokir permanen:
  /// kasir sering men-scan beberapa barang identik berturut-turut.
  static const _sameCodeCooldown = Duration(milliseconds: 1500);

  String? _lastCode;
  DateTime? _lastCodeAt;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Potrait atas permintaan pemilik: memegang HP tegak lebih nyaman saat
    // tangan lain memegang barang. Ini sengaja menukar keuntungan lama
    // landscape untuk barcode 1D — frame pemandu yang dilebarkan menggantikan
    // keuntungan itu. Lihat ADR-043.
    //
    // `portraitUp` saja, tanpa `portraitDown`: preview kamera terbalik tidak
    // pernah berguna. Rotasi preview-nya sendiri diurus mobile_scanner.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _subscription = _controller.barcodes.listen(_onDetect);
    unawaited(_controller.start());
  }

  @override
  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    _subscription = null;

    // Daftar kosong = buang preferensi layar ini, bukan memaksakan kebijakan
    // baru ke seluruh aplikasi. Versi sebelumnya mengunci potrait di sini, dan
    // karena tidak ada layar lain yang menyentuh `SystemChrome`, seluruh
    // aplikasi ikut terkunci potrait setelah scanner dibuka sekali.
    SystemChrome.setPreferredOrientations(const []);

    super.dispose();
    await _controller.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Dialog izin ikut memicu perubahan lifecycle sebelum controller siap,
    // jadi jangan start/stop sampai izinnya ada (anjuran docs v7).
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _subscription = _controller.barcodes.listen(_onDetect);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        unawaited(_subscription?.cancel());
        _subscription = null;
        unawaited(_controller.stop());
    }
  }

  bool _isDuplicate(String code) {
    final at = _lastCodeAt;
    return code == _lastCode &&
        at != null &&
        DateTime.now().difference(at) < _sameCodeCooldown;
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isBusy) return;

    final code = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .firstWhere((value) => value != null && value.isNotEmpty, orElse: () => null);
    if (code == null) return;
    if (_isDuplicate(code)) return;

    setState(() {
      _isBusy = true;
      _lastCode = code;
      _lastCodeAt = DateTime.now();
    });

    final result = await sl<GetProductByBarcode>()(code);
    if (!mounted) return;

    // `Left` berarti gagal membaca database, bukan "barcode tidak terdaftar".
    // Dulu keduanya dilipat jadi satu oleh `getOrElse(() => null)`, jadi setiap
    // error database muncul sebagai "Barcode belum terdaftar" dan tidak ada
    // yang bisa membedakannya — termasuk saat mencari penyebab bug ini.
    final failure = result.fold<Failure?>((f) => f, (_) => null);
    if (failure != null) {
      _showProblem(failure.message);
      setState(() => _isBusy = false);
      return;
    }

    final product = result.getOrElse(() => null);
    if (product == null) {
      await _handleUnknown(code);
    } else if (!product.isActive) {
      // Produk ada tapi dinonaktifkan. Menyebutnya "belum terdaftar" akan
      // menyesatkan: kasir lalu mencoba menambahkannya dan justru ditolak
      // index unik barcode, tanpa petunjuk apa yang sebenarnya salah.
      _showProblem('${product.name} nonaktif — aktifkan dulu di halaman Produk');
    } else {
      // Haptic supaya kasir tahu tanpa harus melihat layar.
      await HapticFeedback.mediumImpact();
      if (!mounted) return;
      context.read<CartBloc>().add(CartEvent.itemAdded(product));
      _showAdded(product);
    }

    if (mounted) setState(() => _isBusy = false);
  }

  /// Masalah yang bukan "barcode tidak terdaftar": error database atau produk
  /// nonaktif. Dibedakan dari snackbar sukses supaya kasir tidak menyangka
  /// barangnya sudah masuk keranjang.
  void _showProblem(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: AppColor.error,
          content: Text(message, style: const TextStyle(color: Colors.white)),
        ),
      );
  }

  void _showAdded(ProductEntity product) {
    final count = context.read<CartBloc>().state.itemCount + 1;
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 900),
          content: Text('${product.name} +1 · $count item'),
        ),
      );
  }

  /// Barcode tidak dikenal: kamera dihentikan dulu supaya tidak terus memicu
  /// sheet, lalu kasir memilih cari manual atau tambah produk.
  Future<void> _handleUnknown(String code) async {
    await _controller.stop();
    if (!mounted) return;

    final action = await showModalBottomSheet<_UnknownAction>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetContext) => _UnknownBarcodeSheet(code: code),
    );
    if (!mounted) return;

    switch (action) {
      case _UnknownAction.addProduct:
        // Form dibuka dengan barcode sudah terisi; ProductBloc global.
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ProductFormScreen(initialBarcode: code),
          ),
        );
        if (!mounted) return;
        // Barcode-nya mungkin baru terdaftar, jadi izinkan scan ulang segera.
        _lastCode = null;
        unawaited(_controller.start());
      case _UnknownAction.searchManually:
        // Kembali ke kasir; pencarian manual ada di sana.
        Navigator.of(context).pop();
      case _UnknownAction.keepScanning:
      case null:
        unawaited(_controller.start());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            errorBuilder: (context, error) => _ScannerError(error: error),
            fit: BoxFit.cover,
          ),
          const _ScannerOverlay(),
          Positioned(
            left: 0,
            right: 0,
            child: _TopControls(
              controller: _controller,
              onClose: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: const _CartSummaryBar(),
          ),
          if (_isBusy)
            const ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= RINGKASAN KERANJANG =================

class _CartSummaryBar extends StatelessWidget {
  const _CartSummaryBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      buildWhen: (p, c) => p.itemCount != c.itemCount,
      builder: (context, cart) {
        if (cart.itemCount == 0) return const SizedBox.shrink();

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.shopping_cart_checkout),
                label: Text('Selesai · ${cart.itemCount} item'),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ================= SHEET BARCODE TIDAK DIKENAL =================

enum _UnknownAction { searchManually, addProduct, keepScanning }

class _UnknownBarcodeSheet extends StatelessWidget {
  const _UnknownBarcodeSheet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Barcode belum terdaftar',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(code, style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_UnknownAction.addProduct),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah produk'),
                ),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_UnknownAction.searchManually),
                  icon: const Icon(Icons.search),
                  label: const Text('Cari manual'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(_UnknownAction.keepScanning),
                  child: const Text('Lanjut scan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= OVERLAY (bingkai pemindaian) =================

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Framenya mengikuti bentuk barcode, bukan bentuk layar: barcode 1D itu
    // lebar dan pendek. Rumus lama (0,6 × lebar, 0,45 × tinggi) menghasilkan
    // kotak yang justru menjulang tinggi di potrait — bentuk paling sulit
    // untuk memasukkan barcode.
    final scanWidth = size.width * 0.85;
    final scanHeight = scanWidth * 0.55;

    return Stack(
      children: [
        // Lapisan gelap dengan lubang di tengah
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black54, BlendMode.srcOut),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: scanWidth,
                  height: scanHeight,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Bingkai putih
        Center(
          child: Container(
            width: scanWidth,
            height: scanHeight,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        
        // Instruksi ditaruh tepat di bawah frame, dihitung dari ukuran frame
        // yang sama. Dulu dipaku ke `bottom: 24`, yang di potrait bertumpuk
        // dengan tombol "Selesai · N item" begitu keranjang terisi.
        Positioned(
          left: 0,
          right: 0,
          top: size.height / 2 + scanHeight / 2 + 20,
          child: Text(
            'Arahkan kamera ke barcode produk',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ================= KONTROL ATAS (tutup, senter, ganti kamera) =================

class _TopControls extends StatelessWidget {
  const _TopControls({required this.controller, required this.onClose});

  final MobileScannerController controller;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _CircleButton(icon: Icons.close, onTap: onClose),
            Row(
              children: [
                ValueListenableBuilder<MobileScannerState>(
                  valueListenable: controller,
                  builder: (context, state, child) {
                    final isTorchOn = state.torchState == TorchState.on;
                    return _CircleButton(
                      icon: isTorchOn ? Icons.flash_on : Icons.flash_off,
                      onTap: () => controller.toggleTorch(),
                    );
                  },
                ),
                const SizedBox(width: 12),
                _CircleButton(
                  icon: Icons.cameraswitch_outlined,
                  onTap: () => controller.switchCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

// ================= ERROR STATE =================

class _ScannerError extends StatelessWidget {
  const _ScannerError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    final String message = switch (error.errorCode) {
      MobileScannerErrorCode.permissionDenied =>
        'Izin kamera ditolak.\nBerikan izin kamera lewat pengaturan aplikasi.',
      MobileScannerErrorCode.unsupported =>
        'Perangkat ini tidak mendukung pemindaian barcode.',
      _ =>
        'Kamera tidak dapat dijalankan.\nCoba tutup dan buka ulang halaman ini.',
    };

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                color: Colors.white54,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 15),
              ),
              if (isPermissionDenied) ...[
                const SizedBox(height: 20),
                // Tanpa tombol ini kasir mentok di layar hitam: izin yang
                // ditolak permanen hanya bisa dipulihkan dari pengaturan OS.
                FilledButton.icon(
                  onPressed: openAppSettings,
                  icon: const Icon(Icons.settings),
                  label: const Text('Buka Pengaturan'),
                ),
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text(
                  'Kembali ke kasir',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

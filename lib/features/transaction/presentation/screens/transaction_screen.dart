import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:henshin/core/utils/page_routes.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen>
    with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _isProcessing = false;
  String? _lastScannedCode;

  @override
  void initState() {
    super.initState();
    // WidgetsBinding.instance.addObserver(this);

    // // Kunci orientasi ke landscape khusus halaman ini
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);

    _controller = MobileScannerController(
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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // // Kembalikan orientasi ke portrait saat keluar halaman
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);

    _controller.dispose();
    super.dispose();
  }

  // Pause/resume kamera saat app masuk background agar hemat baterai
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _controller.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _controller.stop();
    }
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;

    // Cegah scan berulang untuk barcode yang sama beruntun
    if (code == _lastScannedCode) return;

    setState(() {
      _isProcessing = true;
      _lastScannedCode = code;
    });

    // Feedback haptic supaya kasir tahu scan berhasil tanpa harus lihat layar
    await HapticFeedback.mediumImpact();

    // TODO: dispatch ke ProductBloc → ProductBarcodeScanned(code)
    // lalu tambahkan hasilnya ke CartBloc → CartItemAdded(product)

    if (!mounted) return;

    // Kembalikan hasil scan ke halaman pemanggil
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   leading: IconButton(
      //     icon: const Icon(Icons.chevron_left),
      //     onPressed: () => context.go(PageRoutes.dashboard),
      //   ),
      // ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) => _ScannerError(error: error),
            fit: BoxFit.cover,
          ),
          const _ScannerOverlay(),
          Positioned(
            // top: 0,
            left: size.width * 0.5 - 100,
            right: size.width * 0.5 - 100,
            child: _TopControls(
              controller: _controller,
              onClose: () => context.go(PageRoutes.dashboard),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

// ================= OVERLAY (bingkai pemindaian) =================

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Di landscape, area scan dibuat melebar mengikuti bentuk barcode 1D
    final scanWidth = size.width * 0.6;
    final scanHeight = size.height * 0.45;

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
        
        // Instruksi
        Positioned(
          left: 0,
          right: 0,
          bottom: 24,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _CircleButton(icon: Icons.close, onTap: onClose),
            const SizedBox(width: 12),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
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
    String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Izin kamera ditolak.\nBerikan izin kamera lewat pengaturan aplikasi.';
      case MobileScannerErrorCode.unsupported:
        message = 'Perangkat ini tidak mendukung pemindaian barcode.';
      default:
        message = 'Kamera tidak dapat dijalankan.\nCoba tutup dan buka ulang halaman ini.';
    }

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
            ],
          ),
        ),
      ),
    );
  }
}

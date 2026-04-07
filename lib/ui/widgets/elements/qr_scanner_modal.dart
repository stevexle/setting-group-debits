import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../l10n/strings.dart';

class QRScannerModal extends StatefulWidget {
  const QRScannerModal({super.key});

  @override
  State<QRScannerModal> createState() => _QRScannerModalState();
}

class _QRScannerModalState extends State<QRScannerModal> {
  final MobileScannerController controller = MobileScannerController();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: Stack(
          children: [
            MobileScanner(
              controller: controller,
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && !_isDisposed) {
                  final code = barcodes.first.rawValue;
                  if (code != null) {
                    _isDisposed = true; // Prevent double trigger
                    await controller.stop(); // Stop camera for performance
                    if (context.mounted) {
                      Navigator.pop(context, code);
                    }
                  }
                }
              },
              errorBuilder: (context, error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        s.error,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          error.errorCode.name == 'permissionDenied' 
                            ? s.cameraPermission 
                            : error.errorDetails?.message ?? s.error,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(s.close),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Custom QR overlay
            Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: cs.primary, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            // Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      s.scanQR,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          switch (state.torchState) {
                            case TorchState.off:
                              return const Icon(Icons.flash_off_rounded, color: Colors.white);
                            case TorchState.on:
                              return const Icon(Icons.flash_on_rounded, color: Colors.yellow);
                            default:
                              return const Icon(Icons.flash_auto_rounded, color: Colors.white);
                          }
                        },
                      ),
                      onPressed: () => controller.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white),
                      onPressed: () => controller.switchCamera(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

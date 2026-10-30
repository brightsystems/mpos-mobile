import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Scans one barcode with the camera and returns its value (null when cancelled).
class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key, this.title = 'Scan barcode'});

  final String title;

  static Future<String?> scan(BuildContext context, {String title = 'Scan barcode'}) =>
      Navigator.of(context).push<String>(MaterialPageRoute(builder: (_) => BarcodeScanScreen(title: title)));

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen> {
  final _controller = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back);
  final _manual = TextEditingController();
  var _done = false;
  var _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    _manual.dispose();
    super.dispose();
  }

  void _finish(String? code) {
    if (_done || code == null || code.trim().isEmpty) {
      return;
    }
    _done = true;
    Navigator.of(context).pop(code.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Torch',
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (capture) => _finish(capture.barcodes.firstOrNull?.rawValue),
                ),
                Center(
                  child: Container(
                    width: 260,
                    height: 160,
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // A barcode that won't scan can be typed (or read by a Bluetooth scanner acting as a keyboard).
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _manual,
                    decoration: const InputDecoration(
                      labelText: 'Or type the barcode / SKU',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _finish,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: () => _finish(_manual.text), child: const Text('Use')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

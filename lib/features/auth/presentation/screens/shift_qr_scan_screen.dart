import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/device/mpos_device_id.dart';
import 'package:mpos_mobile/core/mock/mock_fixtures.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/auth/presentation/screens/components/qr_scanner_frame.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';

class ShiftQrScanScreen extends StatefulWidget {
  const ShiftQrScanScreen({super.key});

  @override
  State<ShiftQrScanScreen> createState() => _ShiftQrScanScreenState();
}

class _ShiftQrScanScreenState extends State<ShiftQrScanScreen> with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _scanLineController;

  var _handled = false;
  var _isLoggingIn = false;
  String? _deviceId;
  var _torchOn = false;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _scanLineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat(reverse: true);

    _prepareDevice();
  }

  Future<void> _prepareDevice() async {
    final id = await MposDeviceId.getOrCreate(getIt<SharedPreferences>());

    if (mounted) {
      setState(() => _deviceId = id);
    }
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _mockShiftPayload() {
    return jsonEncode({'type': 'mpos_shift', 'token': MockFixtures.mockShiftToken});
  }

  Future<void> _submitShiftLogin(String payload) async {
    if (_handled || _isLoggingIn) {
      return;
    }

    if (_deviceId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device id not ready yet — try scanning again.')),
      );
      return;
    }

    setState(() {
      _handled = true;
      _isLoggingIn = true;
    });

    await _controller.stop();

    final loginPayload = MposConfig.mockMode ? _mockShiftPayload() : payload;

    if (!mounted) {
      return;
    }

    debugPrint('Shift QR login → ${MposConfig.baseUrl} payloadLen=${loginPayload.length}');
    context.read<AuthBloc>().add(AuthShiftQrScanned(loginPayload, _deviceId!, deviceName: 'MPOS Terminal'));
  }

  void _onDetect(BarcodeCapture capture) {
    final value = capture.barcodes.firstOrNull?.rawValue;

    if (value == null || value.isEmpty) {
      return;
    }

    debugPrint('Shift QR detected (${value.length} chars)');
    _submitShiftLogin(value);
  }

  Future<void> _demoLogin() async {
    _handled = false;
    await _submitShiftLogin(_mockShiftPayload());
  }

  Future<void> _resetScanner() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _handled = false;
      _isLoggingIn = false;
    });

    try {
      await _controller.start();
    } catch (_) {
      // Camera may already be running.
    }
  }

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          current is AuthAuthenticated || (current is AuthUnauthenticated && (previous is AuthLoading || _isLoggingIn)),
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          if (mounted) {
            setState(() => _isLoggingIn = false);
          }

          return;
        }

        if (state is AuthUnauthenticated) {
          if (state.message != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message!)));
          }

          await _resetScanner();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Shift login'),
          actions: [
            if (MposConfig.mockMode)
              Padding(
                padding: const EdgeInsets.only(right: AppSizes.padding),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'DEMO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [colorScheme.primary.withValues(alpha: 0.12), colorScheme.surface],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding),
                  child: Column(
                    children: [
                      Text(
                        MposConfig.mockMode
                            ? 'Demo POS — no server required'
                            : 'Scan your shift QR to open the register',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        MposConfig.mockMode
                            ? 'Scan any QR code or tap start below. Login, menu, sales, and e-invoice are fully mocked.'
                            : 'Point the camera at the QR from Branch staff in the web admin.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                    child: _deviceId == null
                        ? const Center(child: AppProgressIndicator())
                        : _QrScannerPanel(
                            controller: _controller,
                            scanLineAnimation: _scanLineController,
                            isLoggingIn: _isLoggingIn,
                            torchOn: _torchOn,
                            onDetect: _onDetect,
                            onToggleTorch: _toggleTorch,
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  child: Column(
                    children: [
                      if (MposConfig.mockMode)
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoggingIn ? null : _demoLogin,
                            icon: const Icon(Icons.play_circle_outline),
                            label: Text(_isLoggingIn ? 'Signing in…' : 'Start demo shift'),
                          ),
                        ),
                      if (MposConfig.mockMode) const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 16, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              MposConfig.mockMode
                                  ? 'Mock mode is on — no localhost API calls'
                                  : 'Live API: ${MposConfig.baseUrl}',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrScannerPanel extends StatelessWidget {
  const _QrScannerPanel({
    required this.controller,
    required this.scanLineAnimation,
    required this.isLoggingIn,
    required this.torchOn,
    required this.onDetect,
    required this.onToggleTorch,
  });

  final MobileScannerController controller;
  final Animation<double> scanLineAnimation;
  final bool isLoggingIn;
  final bool torchOn;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius * 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final frameSize = constraints.maxWidth * 0.72;
          final frameTop = (constraints.maxHeight - frameSize) / 2;
          final horizontalInset = (constraints.maxWidth - frameSize) / 2 + 12;

          return Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(controller: controller, onDetect: onDetect),
              const QrScannerFrame(),
              AnimatedBuilder(
                animation: scanLineAnimation,
                builder: (context, child) {
                  final lineY = frameTop + frameSize * scanLineAnimation.value;

                  return Positioned(
                    left: horizontalInset,
                    right: horizontalInset,
                    top: lineY,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, colorScheme.primary.withValues(alpha: 0.9), Colors.transparent],
                        ),
                        boxShadow: [
                          BoxShadow(color: colorScheme.primary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.small(
                  heroTag: 'torch',
                  onPressed: isLoggingIn ? null : onToggleTorch,
                  backgroundColor: colorScheme.surface.withValues(alpha: 0.9),
                  child: Icon(torchOn ? Icons.flash_on : Icons.flash_off, color: colorScheme.primary),
                ),
              ),
              if (isLoggingIn)
                ColoredBox(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppSizes.radius),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const AppProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            'Opening shift…',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// Darkened overlay with a transparent scan window and corner brackets.
class QrScannerFrame extends StatelessWidget {
  const QrScannerFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth * 0.72;
        final left = (constraints.maxWidth - size) / 2;
        final top = (constraints.maxHeight - size) / 2;
        final rect = Rect.fromLTWH(left, top, size, size);
        final colorScheme = Theme.of(context).colorScheme;

        return CustomPaint(
          painter: _QrScannerFramePainter(scanRect: rect, accent: colorScheme.primary),
          size: Size(constraints.maxWidth, constraints.maxHeight),
        );
      },
    );
  }
}

class _QrScannerFramePainter extends CustomPainter {
  _QrScannerFramePainter({required this.scanRect, required this.accent});

  final Rect scanRect;
  final Color accent;

  static const _cornerLength = 28.0;
  static const _cornerWidth = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final mask = Path.combine(PathOperation.difference, overlay, hole);

    canvas.drawPath(mask, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final border = Paint()
      ..color = accent.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)), border);

    final corner = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = _cornerWidth
      ..strokeCap = StrokeCap.round;

    _drawCorner(canvas, scanRect.topLeft, const Offset(1, 1), corner);
    _drawCorner(canvas, scanRect.topRight, const Offset(-1, 1), corner);
    _drawCorner(canvas, scanRect.bottomLeft, const Offset(1, -1), corner);
    _drawCorner(canvas, scanRect.bottomRight, const Offset(-1, -1), corner);
  }

  void _drawCorner(Canvas canvas, Offset origin, Offset direction, Paint paint) {
    final horizontal = Offset(_cornerLength * direction.dx, 0);
    final vertical = Offset(0, _cornerLength * direction.dy);

    canvas.drawLine(origin, origin + horizontal, paint);
    canvas.drawLine(origin, origin + vertical, paint);
  }

  @override
  bool shouldRepaint(covariant _QrScannerFramePainter oldDelegate) {
    return oldDelegate.scanRect != scanRect || oldDelegate.accent != accent;
  }
}

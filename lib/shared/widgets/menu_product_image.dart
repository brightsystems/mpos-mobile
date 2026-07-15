/// Menu product image with a stable empty-state (avoids endless loading on blank URLs).
import 'package:app_image/app_image.dart';
import 'package:flutter/material.dart';

class MenuProductImage extends StatelessWidget {
  const MenuProductImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.border,
    this.fit = BoxFit.cover,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final BoxFit fit;

  bool get _hasUrl => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(4);
    final placeholder = Icon(Icons.restaurant, color: colorScheme.surfaceDim, size: 32);

    if (!_hasUrl) {
      return Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: radius,
          border: border,
        ),
        child: placeholder,
      );
    }

    return AppImage(
      width: width,
      height: height,
      image: imageUrl!.trim(),
      fit: fit,
      borderRadius: radius,
      border: border,
      backgroundColor: colorScheme.surfaceContainerLowest,
      errorWidget: placeholder,
    );
  }
}

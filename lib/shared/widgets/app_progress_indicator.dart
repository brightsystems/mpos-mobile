import 'package:flutter/material.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';

class AppProgressIndicator extends StatelessWidget {
  const AppProgressIndicator({super.key, this.fontSize = 10, this.showMessage = true, this.message = 'Please wait'});

  final double fontSize;
  final bool showMessage;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSizes.padding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSizes.radius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSizes.padding / 4),
            CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
            if (showMessage)
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.padding),
                child: Text(message, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: fontSize)),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colorScheme.primary.withValues(alpha: 0.12), colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.padding * 1.5),
            child: Column(
              children: [
                const Spacer(),
                Icon(Icons.point_of_sale, size: 72, color: colorScheme.primary),
                const SizedBox(height: AppSizes.padding),
                Text(
                  'MPOS',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Run your business, or open your register.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const Spacer(),
                AppButton(
                  text: 'Sign in with phone',
                  height: 52,
                  onTap: () => context.push('/phone-login'),
                ),
                const SizedBox(height: AppSizes.padding / 1.5),
                AppButton(
                  text: 'Scan shift QR',
                  height: 52,
                  buttonColor: colorScheme.surface,
                  borderColor: colorScheme.primary,
                  textColor: colorScheme.primary,
                  onTap: () => context.push('/shift-login'),
                ),
                const SizedBox(height: AppSizes.padding),
                Text(
                  MposConfig.mockMode ? 'Demo mode — no server required' : 'Owners & staff sign in by phone. Waiters scan a shift QR.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSizes.padding),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

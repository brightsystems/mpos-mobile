import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';

class MposSessionBar extends StatelessWidget implements PreferredSizeWidget {
  const MposSessionBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return AppBar(title: const Text('MPOS'));
        }

        final session = state.session;
        final title = session.userName?.isNotEmpty == true ? session.userName! : session.userPhone;

        return AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (session.branchName != null) Text(session.branchName!, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
          actions: [
            if (MposConfig.mockMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Text('Mock', style: Theme.of(context).textTheme.labelSmall),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              child: const Text('End shift'),
            ),
          ],
        );
      },
    );
  }
}

class MposShiftEndedScreen extends StatelessWidget {
  const MposShiftEndedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 72),
              const SizedBox(height: AppSizes.padding),
              Text('Shift ended', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: AppSizes.radius),
              const Text('Scan your shift QR to start working again.'),
            ],
          ),
        ),
      ),
    );
  }
}

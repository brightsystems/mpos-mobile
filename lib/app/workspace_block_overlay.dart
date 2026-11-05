import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/network/workspace_block.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';

/// Covers the app while the business's MPOS workspace is unpaid, suspended or leaving, with the
/// reason, "Check again" (repeats the last screen's request by reloading the session) and "Sign out".
class WorkspaceBlockOverlay extends StatelessWidget {
  const WorkspaceBlockOverlay({super.key, required this.child, this.onCheckAgain});

  final Widget child;

  /// Asks the API again; a successful business call clears the block.
  final Future<void> Function()? onCheckAgain;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<WorkspaceBlock?>(
      valueListenable: WorkspaceBlockNotifier.instance,
      builder: (context, block, _) => Stack(
        children: [
          child,
          if (block != null) _Notice(block: block, onCheckAgain: onCheckAgain),
        ],
      ),
    );
  }
}

class _Notice extends StatefulWidget {
  const _Notice({required this.block, this.onCheckAgain});

  final WorkspaceBlock block;
  final Future<void> Function()? onCheckAgain;

  @override
  State<_Notice> createState() => _NoticeState();
}

class _NoticeState extends State<_Notice> {
  bool _checking = false;

  Future<void> _check() async {
    setState(() => _checking = true);
    try {
      await widget.onCheckAgain?.call();
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;

    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.padding * 1.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        block.isPaymentRequired ? Icons.account_balance_wallet_outlined : Icons.lock_outline,
                        size: 44,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSizes.padding),
                      Text(
                        block.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSizes.padding / 2),
                      Text(block.message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                      if (block.isPaymentRequired) ...[
                        const SizedBox(height: AppSizes.padding / 2),
                        Text(
                          'Once MPOS confirms your payment, tap Check again to continue.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
                        ),
                      ],
                      const SizedBox(height: AppSizes.padding * 1.5),
                      if (block.code != 'workspace_deleted')
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _checking ? null : _check,
                            icon: _checking
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh),
                            label: const Text('Check again'),
                          ),
                        ),
                      const SizedBox(height: AppSizes.padding / 2),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            WorkspaceBlockNotifier.instance.clear();
                            context.read<AuthBloc>().add(const AuthLogoutRequested());
                          },
                          child: const Text('Sign out'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

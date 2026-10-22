import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/pos/data/shift_api.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';

/// The cashier sells only inside an open shift with a live MoR session on the shift's register,
/// as on the web POS. Until both are there this shows "Start your shift" (register, opening cash,
/// connect to MoR and open the shift); then [child] with a shift bar (close shift; open shifts
/// for managers).
class ShiftGate extends StatefulWidget {
  const ShiftGate({super.key, required this.child});

  final Widget child;

  @override
  State<ShiftGate> createState() => _ShiftGateState();
}

class _ShiftGateState extends State<ShiftGate> {
  final _api = getIt<ShiftApi>();
  final _openingCash = TextEditingController();

  bool _loading = true;
  bool _busy = false;
  String? _error;
  ShiftInfo? _shift;
  MorSessionInfo? _mor;
  List<RegisterInfo> _registers = const [];
  String? _registerId;

  bool get _ready => _shift != null && (_mor?.connected ?? false);

  @override
  void initState() {
    super.initState();
    if (!MposConfig.mockMode) {
      _load();
    }
  }

  @override
  void dispose() {
    _openingCash.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final shifts = await _api.myShifts();
      final open = shifts.where((s) => s.isOpen).firstOrNull;
      final registers = await _api.registers();
      final registerId = open?.sourceId ?? _registerId ?? (registers.isNotEmpty ? registers.first.id : null);
      MorSessionInfo? mor;
      try {
        mor = await _api.morSession(sourceId: registerId);
      } catch (_) {
        mor = null; // no MoR session yet (or several registers and none chosen)
      }
      if (!mounted) return;
      setState(() {
        _shift = open;
        _registers = registers;
        _registerId = registerId;
        _mor = mor;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Connects the register to MoR (when not connected), then opens the shift (when none is open).
  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final registerId = _shift?.sourceId ?? _registerId;
      if (!(_mor?.connected ?? false)) {
        final mor = await _api.connectMor(sourceId: registerId);
        setState(() => _mor = mor);
        if (!mor.connected) {
          throw mor.error ?? 'MoR login failed. Check the register (source) MoR credentials.';
        }
      }
      if (_shift == null) {
        final opening = double.tryParse(_openingCash.text.trim()) ?? 0;
        final shift = await _api.openShift(openingCash: opening, sourceId: registerId);
        _openingCash.clear();
        setState(() => _shift = shift);
        AppSnackBar.show('${shift.sessionNo} open — connected to MoR.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _onRegisterChanged(String? id) async {
    setState(() => _registerId = id);
    try {
      final mor = await _api.morSession(sourceId: id);
      if (mounted) setState(() => _mor = mor);
    } catch (_) {
      if (mounted) setState(() => _mor = null);
    }
  }

  bool get _canManageShifts {
    final state = context.read<AuthBloc>().state;
    if (state is! AuthAuthenticated) return false;
    final session = state.session;
    return session.organizationRole == 'Owner' ||
        session.organizationRole == 'OrgAdmin' ||
        session.role == 'BranchManager' ||
        session.permissions.any((p) => p.toLowerCase() == 'members:branch:manage');
  }

  Future<void> _closeShift() async {
    final shift = _shift;
    if (shift == null) return;
    final counted = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Close ${shift.sessionNo}'),
        content: TextField(
          controller: counted,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Counted cash (ETB)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Close shift')),
        ],
      ),
    );
    if (confirmed != true) return;
    final amount = double.tryParse(counted.text.trim());
    if (amount == null || amount < 0) {
      AppSnackBar.showError('Enter the counted cash.');
      return;
    }
    try {
      final closed = await _api.closeShift(shift.id, closingCash: amount);
      final difference = (closed.closingCash ?? 0) - (closed.expectedCash ?? 0);
      AppSnackBar.show(
        difference.abs() < 0.005
            ? '${closed.sessionNo} closed — cash balanced.'
            : '${closed.sessionNo} closed — cash ${difference > 0 ? 'over' : 'short'} by ${CurrencyFormatter.format(difference.abs())}.',
      );
      await _load();
    } catch (e) {
      AppSnackBar.showError(e.toString());
    }
  }

  Future<void> _openBranchShifts() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BranchShiftsSheet(api: _api),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    // The demo (mock) mode has no MoR or shifts.
    if (MposConfig.mockMode) {
      return widget.child;
    }

    if (_loading && _shift == null && _mor == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_ready) {
      return _buildStart(context);
    }

    return Column(
      children: [
        _buildBar(context),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildBar(BuildContext context) {
    final theme = Theme.of(context);
    final shift = _shift!;
    return Material(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSizes.padding, 6, 4, 6),
        child: Row(
          children: [
            Icon(Icons.verified, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${shift.sessionNo} · ${shift.sourceName ?? _mor?.sourceName ?? 'Register'} · MoR connected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Shift',
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'close':
                    _closeShift();
                  case 'branch':
                    _openBranchShifts();
                  case 'refresh':
                    _load();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'close', child: Text('Close shift')),
                if (_canManageShifts) const PopupMenuItem(value: 'branch', child: Text('Open shifts at this branch')),
                const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStart(BuildContext context) {
    final theme = Theme.of(context);
    final connected = _mor?.connected ?? false;
    final label = _shift != null
        ? 'Connect to MoR'
        : connected
        ? 'Open shift'
        : 'Connect to MoR & open shift';

    Widget step(bool done, String text) => Row(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: done ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: done ? FontWeight.w600 : null)),
        ),
      ],
    );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          Text('Start your shift', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Connect to the Ministry of Revenue and open your shift before selling, so invoices and receipts register without interruption.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: AppSizes.padding),
          step(
            connected,
            connected
                ? 'MoR session — connected${_mor?.sourceName != null ? ' (${_mor!.sourceName})' : ''}'
                : 'MoR session — not connected',
          ),
          const SizedBox(height: 6),
          step(_shift != null, _shift != null ? 'Shift — ${_shift!.sessionNo} open' : 'Shift — not open'),
          const SizedBox(height: AppSizes.padding),
          if (_shift == null) ...[
            if (_registers.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: _registerId,
                decoration: const InputDecoration(labelText: 'Register'),
                items: [for (final r in _registers) DropdownMenuItem(value: r.id, child: Text(r.name))],
                onChanged: _busy ? null : _onRegisterChanged,
              ),
              const SizedBox(height: AppSizes.padding),
            ],
            TextField(
              controller: _openingCash,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Opening cash (ETB)', hintText: '0.00'),
            ),
            const SizedBox(height: AppSizes.padding),
          ],
          if (_error != null) ...[
            Text(_error!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error)),
            const SizedBox(height: AppSizes.padding),
          ],
          FilledButton.icon(
            onPressed: _busy ? null : _start,
            icon: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.login),
            label: Text(label),
          ),
          if (_canManageShifts) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _openBranchShifts,
              icon: const Icon(Icons.group),
              label: const Text('Open shifts at this branch'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Every open shift at the branch (managers): close with a cash count, or force close with a reason.
class _BranchShiftsSheet extends StatefulWidget {
  const _BranchShiftsSheet({required this.api});

  final ShiftApi api;

  @override
  State<_BranchShiftsSheet> createState() => _BranchShiftsSheetState();
}

class _BranchShiftsSheetState extends State<_BranchShiftsSheet> {
  List<ShiftInfo> _shifts = const [];
  bool _loading = true;
  String? _busyId;
  final _counted = <String, TextEditingController>{};
  final _reasons = <String, TextEditingController>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [..._counted.values, ..._reasons.values]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final shifts = await widget.api.branchOpenShifts();
      if (!mounted) return;
      setState(() {
        _shifts = shifts;
        for (final s in shifts) {
          _counted.putIfAbsent(s.id, TextEditingController.new);
          _reasons.putIfAbsent(s.id, TextEditingController.new);
        }
      });
    } catch (e) {
      AppSnackBar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _close(ShiftInfo shift, {required bool force}) async {
    final counted = double.tryParse(_counted[shift.id]!.text.trim());
    final reason = _reasons[shift.id]!.text.trim();
    if (!force && counted == null) {
      AppSnackBar.showError('Enter the counted cash first.');
      return;
    }
    if (force && reason.length < 3) {
      AppSnackBar.showError('Give a reason for closing this shift.');
      return;
    }
    setState(() => _busyId = shift.id);
    try {
      if (force) {
        await widget.api.forceCloseShift(shift.id, reason: reason);
      } else {
        await widget.api.closeShift(shift.id, closingCash: counted!);
      }
      AppSnackBar.show('${shift.sessionNo} (${shift.openedByName ?? 'cashier'}) is closed. Its register is free.');
      await _load();
    } catch (e) {
      AppSnackBar.showError(e.toString());
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSizes.padding,
          right: AppSizes.padding,
          top: AppSizes.padding,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Open shifts at this branch',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_shifts.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No shifts are open at this branch.'))
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final s in _shifts)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${s.openedByName ?? 'Cashier'} · ${s.sessionNo}',
                                style: theme.textTheme.titleSmall,
                              ),
                              Text(
                                '${s.sourceName ?? 'No register'} · since ${MaterialLocalizations.of(context).formatShortDate(s.openedAt)} '
                                '${TimeOfDay.fromDateTime(s.openedAt).format(context)} · opening ${CurrencyFormatter.format(s.openingCash)}',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _counted[s.id],
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      decoration: const InputDecoration(isDense: true, labelText: 'Counted cash'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: _busyId == s.id ? null : () => _close(s, force: false),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _reasons[s.id],
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        labelText: 'Reason (e.g. cashier went home)',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton(
                                    onPressed: _busyId == s.id ? null : () => _close(s, force: true),
                                    style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                                    child: const Text('Force close'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

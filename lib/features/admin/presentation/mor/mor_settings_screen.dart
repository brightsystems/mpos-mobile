import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/network/mpos_api_client.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class MorSettingsScreen extends StatefulWidget {
  const MorSettingsScreen({super.key});

  @override
  State<MorSettingsScreen> createState() => _MorSettingsScreenState();
}

class _MorSettingsScreenState extends State<MorSettingsScreen> {
  final _repository = getIt<AdminRepository>();
  final _apiClient = getIt<MposApiClient>();
  late String _orgId;
  bool _loading = true;
  String? _error;

  // INSA certificate request status (read-only; managed from the web admin).
  String? _certStatus;
  String? _certEmailedAt;
  String? _certError;

  final _systemNumber = TextEditingController();
  final _systemType = TextEditingController(text: 'POS');
  final _baseUrl = TextEditingController();
  final _clientId = TextEditingController();
  final _clientSecret = TextEditingController();
  final _apiKey = TextEditingController();
  bool _hasClientId = false;
  bool _hasClientSecret = false;
  bool _hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _orgId = sessionOf(context)?.organizationId ?? '';
    _load();
  }

  @override
  void dispose() {
    for (final c in [_systemNumber, _systemType, _baseUrl, _clientId, _clientSecret, _apiKey]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getMorSettings(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        final m = result.data;
        if (m != null) {
          _systemNumber.text = m.systemNumber;
          _systemType.text = m.systemType ?? 'POS';
          _baseUrl.text = m.morBaseUrl ?? '';
          // Credentials are never returned by the API — only presence flags.
          _hasClientId = m.hasClientId || (m.morClientId?.isNotEmpty ?? false);
          _hasClientSecret = m.hasClientSecret;
          _hasApiKey = m.hasApiKey || (m.morApiKey?.isNotEmpty ?? false);
        }
      } else {
        _error = result.error?.toString();
      }
    });
    await _loadCertificateStatus();
  }

  Future<void> _loadCertificateStatus() async {
    final response = await _apiClient.get<Map<String, dynamic>?>(
      '/organizations/$_orgId/mor-settings/certificate-request',
      authenticated: true,
      fromJson: (json) => json as Map<String, dynamic>?,
    );
    if (!mounted) return;
    setState(() {
      if (response.success) {
        final data = response.data;
        _certStatus = data == null ? 'Not requested' : (data['status'] as String? ?? 'Unknown');
        _certEmailedAt = data?['emailedAt'] as String?;
        _certError = data?['emailError'] as String?;
      } else {
        _certStatus = null;
      }
    });
  }

  Future<void> _save() async {
    if (_systemNumber.text.trim().isEmpty) {
      AppSnackBar.showError('System number is required.');
      return;
    }

    final body = <String, dynamic>{
      'systemNumber': _systemNumber.text.trim(),
      if (_systemType.text.trim().isNotEmpty) 'systemType': _systemType.text.trim(),
      if (_baseUrl.text.trim().isNotEmpty) 'morBaseUrl': _baseUrl.text.trim(),
      if (_clientId.text.trim().isNotEmpty) 'morClientId': _clientId.text.trim(),
      if (_clientSecret.text.trim().isNotEmpty) 'morClientSecret': _clientSecret.text.trim(),
      if (_apiKey.text.trim().isNotEmpty) 'morApiKey': _apiKey.text.trim(),
    };
    await runAdminAction<MorSettingsModel>(
      context,
      () => _repository.updateMorSettings(_orgId, body),
      successMessage: 'MOR settings saved.',
    );
    if (!mounted) return;
    setState(() {
      if (_clientId.text.trim().isNotEmpty) _hasClientId = true;
      if (_clientSecret.text.trim().isNotEmpty) _hasClientSecret = true;
      if (_apiKey.text.trim().isNotEmpty) _hasApiKey = true;
      _clientId.clear();
      _clientSecret.clear();
      _apiKey.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MOR e-invoice')),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                Text(
                  'Seller identity is managed under Business management. Configure MOR API credentials here.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSizes.padding),
                AppTextField(controller: _systemNumber, labelText: 'System number *'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _systemType, labelText: 'System type'),
                const SizedBox(height: AppSizes.padding),
                Text(
                  'MOR credentials',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(
                  controller: _clientId,
                  labelText: 'Client id (optional)',
                  hintText: _hasClientId ? 'Saved — leave blank to keep' : null,
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(
                  controller: _clientSecret,
                  labelText: 'Client secret (optional)',
                  obscureText: true,
                  hintText: _hasClientSecret ? '•••••• Saved — leave blank to keep' : null,
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(
                  controller: _apiKey,
                  labelText: 'API key (optional)',
                  obscureText: true,
                  hintText: _hasApiKey ? '•••••• Saved — leave blank to keep' : null,
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _baseUrl, labelText: 'MOR base URL (optional)'),
                const SizedBox(height: AppSizes.padding),
                AppButton(text: 'Save settings', onTap: _save),
                const SizedBox(height: AppSizes.padding),
                Text(
                  'INSA digital certificate',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSizes.padding / 2),
                _CertificateStatusCard(status: _certStatus, emailedAt: _certEmailedAt, emailError: _certError),
              ],
            ),
    );
  }
}

class _CertificateStatusCard extends StatelessWidget {
  const _CertificateStatusCard({required this.status, this.emailedAt, this.emailError});

  final String? status;
  final String? emailedAt;
  final String? emailError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final effective = status ?? 'Unavailable';

    final (Color color, IconData icon) = switch (effective) {
      'Emailed' => (Colors.green, Icons.mark_email_read_outlined),
      'Generated' => (Colors.orange, Icons.pending_outlined),
      'Issued' => (Colors.green, Icons.verified_outlined),
      'Not requested' => (scheme.outline, Icons.info_outline),
      _ => (scheme.outline, Icons.help_outline),
    };

    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.surfaceContainer),
        borderRadius: BorderRadius.circular(AppSizes.radius),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: AppSizes.padding / 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certificate request: $effective',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (emailedAt != null)
                  Text('Request package emailed to contact person: $emailedAt', style: Theme.of(context).textTheme.bodySmall),
                if (emailError != null)
                  Text(
                    'Email failed: $emailError',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                Text(
                  'Generate and email the request from the web admin (MOR settings).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

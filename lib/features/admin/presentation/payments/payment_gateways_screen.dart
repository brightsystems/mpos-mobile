import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class PaymentGatewaysScreen extends StatefulWidget {
  const PaymentGatewaysScreen({super.key});

  @override
  State<PaymentGatewaysScreen> createState() => _PaymentGatewaysScreenState();
}

class _PaymentGatewaysScreenState extends State<PaymentGatewaysScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _loading = true;
  String? _error;

  bool _enableCash = true;
  bool _enableChapa = false;
  bool _enableTelebirr = false;

  final _merchantCode = TextEditingController();
  final _fabricAppId = TextEditingController();
  final _merchantAppId = TextEditingController();
  final _baseUrl = TextEditingController();
  final _webBaseUrl = TextEditingController();
  final _fabricAppSecret = TextEditingController();
  final _privateKeyPem = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orgId = sessionOf(context)?.organizationId ?? '';
    _load();
  }

  @override
  void dispose() {
    _merchantCode.dispose();
    _fabricAppId.dispose();
    _merchantAppId.dispose();
    _baseUrl.dispose();
    _webBaseUrl.dispose();
    _fabricAppSecret.dispose();
    _privateKeyPem.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getPaymentSettings(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess && result.data != null) {
        final s = result.data!;
        _enableCash = s.enableCash;
        _enableChapa = s.enableChapa;
        _enableTelebirr = s.enableTelebirr;
        _merchantCode.text = s.telebirrMerchantCode ?? '';
        _fabricAppId.text = s.telebirrFabricAppId ?? '';
        _merchantAppId.text = s.telebirrMerchantAppId ?? '';
        _baseUrl.text = s.telebirrBaseUrl ?? '';
        _webBaseUrl.text = s.telebirrWebBaseUrl ?? '';
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _save() async {
    final body = <String, dynamic>{
      'enableCash': _enableCash,
      'enableChapa': _enableChapa,
      'enableTelebirr': _enableTelebirr,
      if (_enableTelebirr) ...{
        if (_merchantCode.text.trim().isNotEmpty) 'telebirrMerchantCode': _merchantCode.text.trim(),
        if (_fabricAppId.text.trim().isNotEmpty) 'telebirrFabricAppId': _fabricAppId.text.trim(),
        if (_merchantAppId.text.trim().isNotEmpty) 'telebirrMerchantAppId': _merchantAppId.text.trim(),
        if (_baseUrl.text.trim().isNotEmpty) 'telebirrBaseUrl': _baseUrl.text.trim(),
        if (_webBaseUrl.text.trim().isNotEmpty) 'telebirrWebBaseUrl': _webBaseUrl.text.trim(),
        if (_fabricAppSecret.text.trim().isNotEmpty) 'telebirrFabricAppSecret': _fabricAppSecret.text.trim(),
        if (_privateKeyPem.text.trim().isNotEmpty) 'telebirrPrivateKeyPem': _privateKeyPem.text.trim(),
      },
    };
    await runAdminAction<PaymentSettingsModel>(
      context,
      () => _repository.updatePaymentSettings(_orgId, body),
      successMessage: 'Payment settings saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment gateways')),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                SwitchListTile(
                  title: const Text('Cash'),
                  value: _enableCash,
                  onChanged: (v) => setState(() => _enableCash = v),
                ),
                SwitchListTile(
                  title: const Text('Chapa'),
                  value: _enableChapa,
                  onChanged: (v) => setState(() => _enableChapa = v),
                ),
                SwitchListTile(
                  title: const Text('Telebirr'),
                  value: _enableTelebirr,
                  onChanged: (v) => setState(() => _enableTelebirr = v),
                ),
                if (_enableTelebirr) ...[
                  const Divider(),
                  Text(
                    'Telebirr credentials',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _merchantCode, labelText: 'Merchant code'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _fabricAppId, labelText: 'Fabric app id'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _merchantAppId, labelText: 'Merchant app id'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _fabricAppSecret, labelText: 'Fabric app secret', obscureText: true),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _privateKeyPem, labelText: 'Private key (PEM)', maxLines: 4),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _baseUrl, labelText: 'API base URL'),
                  const SizedBox(height: AppSizes.padding / 2),
                  AppTextField(controller: _webBaseUrl, labelText: 'Web base URL'),
                ],
                const SizedBox(height: AppSizes.padding),
                AppButton(text: 'Save settings', onTap: _save),
              ],
            ),
    );
  }
}

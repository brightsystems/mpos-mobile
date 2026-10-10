import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/device/mpos_device_id.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/domain/entities/sign_in_result_entity.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();

  String? _deviceId;
  String? _requestId;
  bool _codeStep = false;

  /// Set when the phone is known in several workspaces: the user picks one.
  AuthNeedsTenantSelection? _tenantStep;

  @override
  void initState() {
    super.initState();
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
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _sendCode() {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      AppSnackBar.showError('Enter your phone number.');
      return;
    }
    context.read<AuthBloc>().add(AuthOtpRequested(phone));
  }

  void _verify() {
    final code = _code.text.trim();
    if (code.isEmpty || _requestId == null || _deviceId == null) {
      AppSnackBar.showError('Enter the code sent to your phone.');
      return;
    }
    context.read<AuthBloc>().add(
      AuthOtpVerified(requestId: _requestId!, code: code, deviceId: _deviceId!, deviceName: 'MPOS Mobile'),
    );
  }

  void _chooseTenant(TenantChoiceEntity choice) {
    final step = _tenantStep;
    if (step == null || _deviceId == null) {
      return;
    }
    context.read<AuthBloc>().add(
      AuthTenantChosen(challengeId: step.challengeId, tenantId: choice.tenantId, deviceId: _deviceId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sign in with phone')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            setState(() {
              _requestId = state.requestId;
              _codeStep = true;
              if (state.devOtp != null) {
                _code.text = state.devOtp!;
              }
            });
            AppSnackBar.show(state.devOtp != null ? 'Demo code: ${state.devOtp}' : 'Code sent to ${state.phone}.');
          }

          if (state is AuthNeedsTenantSelection) {
            setState(() => _tenantStep = state);
          }

          if (state is AuthUnauthenticated && state.message != null) {
            // A failed workspace choice (e.g. expired challenge) starts over with a new code.
            setState(() {
              if (_tenantStep != null) {
                _tenantStep = null;
                _codeStep = false;
                _code.clear();
              }
            });
            AppSnackBar.showError(state.message!);
          }
        },
        builder: (context, state) {
          final busy = state is AuthLoading || state is AuthOtpSending;
          final tenantStep = _tenantStep;

          if (tenantStep != null) {
            return _buildTenantStep(context, tenantStep, busy);
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSizes.padding),
                  Text(
                    _codeStep ? 'Enter the code' : 'What is your phone number?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _codeStep
                        ? 'We sent a 6-digit code to ${_phone.text.trim()}.'
                        : 'Use the same phone you used when creating your business. Example: 0911… or +251911…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSizes.padding * 1.5),
                  if (!_codeStep) ...[
                    AppTextField(
                      controller: _phone,
                      labelText: 'Phone number',
                      hintText: '0911234567',
                      keyboardType: TextInputType.phone,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSizes.padding),
                    AppButton(
                      text: busy ? 'Sending…' : 'Send code',
                      height: 52,
                      enabled: !busy && _deviceId != null,
                      onTap: _sendCode,
                    ),
                  ] else ...[
                    AppTextField(
                      controller: _code,
                      labelText: 'Verification code',
                      hintText: '123456',
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                    ),
                    const SizedBox(height: AppSizes.padding),
                    AppButton(
                      text: busy ? 'Verifying…' : 'Verify & continue',
                      height: 52,
                      enabled: !busy,
                      onTap: _verify,
                    ),
                    const SizedBox(height: AppSizes.padding / 2),
                    TextButton(
                      onPressed: busy ? null : () => setState(() => _codeStep = false),
                      child: const Text('Change phone number'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTenantStep(BuildContext context, AuthNeedsTenantSelection step, bool busy) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          const SizedBox(height: AppSizes.padding),
          Text(
            'Choose a workspace',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            '${_phone.text.trim()} is registered with more than one business. Choose where to sign in.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSizes.padding * 1.5),
          for (final choice in step.choices)
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(choice.businessName.isEmpty ? choice.slug : choice.businessName),
                subtitle: choice.slug.isEmpty ? null : Text(choice.slug),
                trailing: busy ? null : const Icon(Icons.chevron_right),
                enabled: !busy,
                onTap: () => _chooseTenant(choice),
              ),
            ),
          if (busy) ...[const SizedBox(height: AppSizes.padding), const Center(child: CircularProgressIndicator())],
          const SizedBox(height: AppSizes.padding / 2),
          TextButton(
            onPressed: busy
                ? null
                : () => setState(() {
                    _tenantStep = null;
                    _codeStep = false;
                    _code.clear();
                  }),
            child: const Text('Use another phone number'),
          ),
        ],
      ),
    );
  }
}

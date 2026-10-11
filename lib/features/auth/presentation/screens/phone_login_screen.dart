import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/device/mpos_device_id.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

/// Sign-in with phone + password. An SMS code is only used to set the first password (the account
/// has none yet) or to reset a forgotten one.
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  static const _deviceName = 'MPOS Mobile';

  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  String? _deviceId;

  /// Set while the user enters the SMS code and a new password.
  AuthOtpSent? _setPasswordStep;

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
    _password.dispose();
    _code.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _signIn() {
    final phone = _phone.text.trim();
    if (phone.isEmpty || _password.text.isEmpty) {
      AppSnackBar.showError('Enter your phone number and password.');
      return;
    }
    context.read<AuthBloc>().add(
      AuthPasswordLoginRequested(phone: phone, password: _password.text, deviceId: _deviceId!, deviceName: _deviceName),
    );
  }

  void _forgotPassword() {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      AppSnackBar.showError('Enter your phone number first.');
      return;
    }
    context.read<AuthBloc>().add(AuthOtpRequested(phone));
  }

  void _savePassword() {
    final step = _setPasswordStep;
    if (step == null || _deviceId == null) {
      return;
    }

    if (_code.text.trim().length < 6) {
      AppSnackBar.showError('Enter the 6-digit code sent to your phone.');
      return;
    }

    final problem = AuthBloc.passwordProblem(_newPassword.text);
    if (problem != null) {
      AppSnackBar.showError(problem);
      return;
    }

    if (_newPassword.text != _confirmPassword.text) {
      AppSnackBar.showError('The passwords do not match.');
      return;
    }

    context.read<AuthBloc>().add(
      AuthPasswordSetSubmitted(
        requestId: step.requestId,
        code: _code.text.trim(),
        newPassword: _newPassword.text,
        deviceId: _deviceId!,
        deviceName: _deviceName,
      ),
    );
  }

  void _backToSignIn() {
    setState(() {
      _setPasswordStep = null;
      _code.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            setState(() {
              _setPasswordStep = state;
              _code.text = state.devOtp ?? '';
              _newPassword.clear();
              _confirmPassword.clear();
            });
            AppSnackBar.show(state.devOtp != null ? 'Demo code: ${state.devOtp}' : 'Code sent to ${state.phone}.');
          }

          if (state is AuthUnauthenticated && state.message != null) {
            AppSnackBar.showError(state.message!);
          }
        },
        builder: (context, state) {
          final busy = state is AuthLoading || state is AuthOtpSending;
          final step = _setPasswordStep;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: step == null ? _buildSignIn(context, busy) : _buildSetPassword(context, step, busy),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSignIn(BuildContext context, bool busy) {
    final colorScheme = Theme.of(context).colorScheme;

    return [
      const SizedBox(height: AppSizes.padding),
      Text('Welcome back', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text(
        'Sign in with your phone number and password. Example: 0911… or +251911…',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSizes.padding * 1.5),
      AppTextField(
        controller: _phone,
        labelText: 'Phone number',
        hintText: '0911234567',
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        autofocus: true,
      ),
      const SizedBox(height: AppSizes.padding),
      AppTextField(
        controller: _password,
        labelText: 'Password',
        obscureText: true,
        textInputAction: TextInputAction.done,
        onEditingComplete: busy || _deviceId == null ? null : _signIn,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(onPressed: busy ? null : _forgotPassword, child: const Text('Forgot password?')),
      ),
      const SizedBox(height: AppSizes.padding / 2),
      AppButton(
        text: busy ? 'Signing in…' : 'Sign in',
        height: 52,
        enabled: !busy && _deviceId != null,
        onTap: _signIn,
      ),
      const SizedBox(height: AppSizes.padding),
      Text(
        'First time, or no password yet? Enter your phone and tap "Forgot password?" — we\'ll text you a code to set one.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
    ];
  }

  List<Widget> _buildSetPassword(BuildContext context, AuthOtpSent step, bool busy) {
    final colorScheme = Theme.of(context).colorScheme;
    final firstTime = step.reason == PasswordSetupReason.firstTime;

    return [
      const SizedBox(height: AppSizes.padding),
      Text(
        firstTime ? 'Create your password' : 'Reset your password',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Text(
        '${firstTime ? 'Your account has no password yet.' : 'Other devices will be signed out.'} '
        'Enter the 6-digit code we sent to ${step.phone}.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: AppSizes.padding * 1.5),
      AppTextField(
        controller: _code,
        labelText: 'Verification code',
        hintText: '123456',
        keyboardType: TextInputType.number,
        maxLength: 6,
        autofocus: true,
      ),
      const SizedBox(height: AppSizes.padding),
      AppTextField(
        controller: _newPassword,
        labelText: 'New password',
        hintText: 'At least 8 characters, a letter and a number',
        obscureText: true,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: AppSizes.padding),
      AppTextField(
        controller: _confirmPassword,
        labelText: 'Confirm password',
        obscureText: true,
        textInputAction: TextInputAction.done,
        onEditingComplete: busy ? null : _savePassword,
      ),
      const SizedBox(height: AppSizes.padding),
      AppButton(text: busy ? 'Saving…' : 'Save password & sign in', height: 52, enabled: !busy, onTap: _savePassword),
      const SizedBox(height: AppSizes.padding / 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: busy ? null : _backToSignIn, child: const Text('Back to sign in')),
          TextButton(
            onPressed: busy
                ? null
                : () => context.read<AuthBloc>().add(AuthOtpRequested(step.phone, reason: step.reason)),
            child: const Text('Resend code'),
          ),
        ],
      ),
    ];
  }
}

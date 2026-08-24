import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_dropdown_field.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:mpos_mobile/features/auth/presentation/bloc/auth_state.dart';
import 'package:mpos_mobile/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:mpos_mobile/features/pos/domain/entities/business_profile_entity.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

const _settlementLevels = ['Organization', 'Branch'];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _repository = getIt<OnboardingRepository>();

  final _orgName = TextEditingController();
  final _legalName = TextEditingController();
  final _tin = TextEditingController();
  final _vat = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _region = TextEditingController(text: '1');
  final _wereda = TextEditingController();
  final _city = TextEditingController();
  final _branchName = TextEditingController(text: 'Main branch');
  final _branchCity = TextEditingController();
  final _branchPhone = TextEditingController();
  final _branchAddress = TextEditingController();
  String _type = 'Cafeteria';
  String _settlementLevel = _settlementLevels.first;
  List<BusinessProfileEntity> _profiles = const [BusinessProfileEntity.cafeteria];
  BusinessProfileEntity? _selectedProfile = BusinessProfileEntity.cafeteria;
  bool _loadingTypes = true;

  @override
  void initState() {
    super.initState();
    _loadTypes();
  }

  @override
  void dispose() {
    for (final c in [
      _orgName,
      _legalName,
      _tin,
      _vat,
      _email,
      _phone,
      _region,
      _wereda,
      _city,
      _branchName,
      _branchCity,
      _branchPhone,
      _branchAddress,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final result = await _repository.listBusinessTypes();
    if (!mounted) return;

    setState(() {
      _loadingTypes = false;
      if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
        _profiles = result.data!;
        _type = _profiles.first.code;
        _selectedProfile = _profiles.first;
      }
    });
  }

  Future<void> _submit() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthNeedsOnboarding && authState is! AuthAuthenticated) {
      return;
    }
    final session = authState is AuthNeedsOnboarding
        ? authState.session
        : (authState as AuthAuthenticated).session;

    final orgName = _orgName.text.trim();
    final legalName = _legalName.text.trim().isEmpty ? orgName : _legalName.text.trim();
    final phone = _phone.text.trim().isEmpty ? session.userPhone : _phone.text.trim();
    final email = _email.text.trim();
    final wereda = _wereda.text.trim();
    final vat = _vat.text.trim();

    if (orgName.isEmpty ||
        _tin.text.trim().isEmpty ||
        _branchName.text.trim().isEmpty ||
        legalName.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        wereda.isEmpty ||
        vat.isEmpty) {
      AppSnackBar.showError(
        'Business name, legal name, TIN, VAT, email, phone, wereda, and branch name are required.',
      );
      return;
    }

    final body = <String, dynamic>{
      'organizationName': orgName,
      'type': _type,
      'tin': _tin.text.trim(),
      'legalName': legalName,
      'email': email,
      'phone': phone,
      'region': _region.text.trim().isEmpty ? '1' : _region.text.trim(),
      'wereda': wereda,
      'vatNumber': vat,
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      'settlementLevel': _settlementLevel,
      'branchName': _branchName.text.trim(),
      if (_branchCity.text.trim().isNotEmpty)
        'branchCity': _branchCity.text.trim()
      else if (_city.text.trim().isNotEmpty)
        'branchCity': _city.text.trim(),
      'branchPhone': _branchPhone.text.trim().isNotEmpty ? _branchPhone.text.trim() : phone,
      if (_branchAddress.text.trim().isNotEmpty) 'branchAddress': _branchAddress.text.trim(),
      'branchTimezone': 'Africa/Addis_Ababa',
      'deviceId': session.deviceId,
      'deviceName': 'MPOS Mobile',
    };

    final result = await AppDialog.showProgress(
      () => _repository.createBusiness(body, deviceId: session.deviceId),
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      context.read<AuthBloc>().add(AuthSessionUpdated(result.data!));
      return;
    }

    AppSnackBar.showError(result.error?.toString() ?? 'Could not create your business. Try again.');
  }

  @override
  Widget build(BuildContext context) {
    final profile = _selectedProfile;
    final authState = context.watch<AuthBloc>().state;
    final isAdditionalBusiness = authState is AuthAuthenticated;

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdditionalBusiness ? 'New business' : 'Set up your business'),
        actions: [
          TextButton(
            onPressed: () => context.read<AuthBloc>().add(const AuthLogoutRequested()),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSizes.padding),
        children: [
          Text(
            isAdditionalBusiness ? 'Add another business' : 'Tell us about your business',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            isAdditionalBusiness
                ? 'Create another organization under this phone number.'
                : 'Your business type seeds the catalog, labels, and default order flow.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(controller: _orgName, labelText: 'Business name'),
          const SizedBox(height: AppSizes.padding / 2),
          AdminDropdownField<String>(
            label: 'Business type',
            value: _type,
            items: _profiles
                .map((profile) => DropdownMenuItem(value: profile.code, child: Text(profile.displayName)))
                .toList(),
            onChanged: (value) {
              if (_loadingTypes) return;
              setState(() {
                _type = value;
                _selectedProfile = _profiles.where((profile) => profile.code == value).firstOrNull;
              });
            },
          ),
          if (profile != null) ...[
            const SizedBox(height: AppSizes.padding / 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.padding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSizes.radius),
                border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${profile.displayName} setup',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(profile.description, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Floor: ${profile.floorMode} · ${profile.vocabulary.ticket} · ${profile.defaultWorkflowTemplate}',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _legalName, labelText: 'Legal name *'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _tin, labelText: 'TIN *', keyboardType: TextInputType.number),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _vat, labelText: 'VAT number *'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _email, labelText: 'Business email *', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _phone, labelText: 'Business phone *', keyboardType: TextInputType.phone),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _region, labelText: 'Region *'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _wereda, labelText: 'Wereda *'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _city, labelText: 'City (optional)'),
          const SizedBox(height: AppSizes.padding / 2),
          AdminDropdownField<String>(
            label: 'Settlement level',
            value: _settlementLevel,
            items: _settlementLevels.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
            onChanged: (value) => setState(() => _settlementLevel = value),
          ),
          const SizedBox(height: AppSizes.padding),
          Text(
            'First branch',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _branchName, labelText: 'Branch name'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _branchCity, labelText: 'City (optional)'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _branchPhone, labelText: 'Branch phone (optional)', keyboardType: TextInputType.phone),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _branchAddress, labelText: 'Address (optional)'),
          const SizedBox(height: AppSizes.padding),
          AppButton(text: 'Create business', onTap: _submit),
        ],
      ),
    );
  }
}

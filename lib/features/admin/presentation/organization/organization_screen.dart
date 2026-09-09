import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_dropdown_field.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

const kOrgTypes = [
  'Cafeteria',
  'Shop',
  'Store',
  'Hotel',
  'ConsultancyService',
  'MedicalService',
  'Other',
];
const kSettlementLevels = ['Organization', 'Branch'];

String orgTypeLabel(String code) => switch (code) {
  'ConsultancyService' => 'Consultancy Service',
  'MedicalService' => 'Medical Service',
  _ => code,
};

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _loading = true;
  String? _error;

  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _tin = TextEditingController();
  final _vat = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _region = TextEditingController(text: '1');
  final _wereda = TextEditingController();
  final _city = TextEditingController();
  final _subCity = TextEditingController();
  final _locality = TextEditingController();
  final _houseNumber = TextEditingController();
  String _type = kOrgTypes.first;
  String _settlementLevel = kSettlementLevels.first;

  @override
  void initState() {
    super.initState();
    _orgId = sessionOf(context)?.organizationId ?? '';
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _name,
      _legalName,
      _tin,
      _vat,
      _email,
      _phone,
      _region,
      _wereda,
      _city,
      _subCity,
      _locality,
      _houseNumber,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getOrganization(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess && result.data != null) {
        final org = result.data!;
        _name.text = org.name;
        _legalName.text = org.legalName;
        _tin.text = org.tin;
        _vat.text = org.vatNumber;
        _email.text = org.email;
        _phone.text = org.phone;
        _region.text = org.region.isEmpty ? '1' : org.region;
        _wereda.text = org.wereda;
        _city.text = org.city ?? '';
        _subCity.text = org.subCity ?? '';
        _locality.text = org.locality ?? '';
        _houseNumber.text = org.houseNumber ?? '';
        _type = kOrgTypes.contains(org.type) ? org.type : kOrgTypes.first;
        _settlementLevel = kSettlementLevels.contains(org.settlementLevel)
            ? org.settlementLevel
            : kSettlementLevels.first;
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty ||
        _legalName.text.trim().isEmpty ||
        _tin.text.trim().isEmpty ||
        _vat.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _wereda.text.trim().isEmpty) {
      AppSnackBar.showError('Name, legal name, TIN, VAT, email, phone, and wereda are required.');
      return;
    }
    if (!RegExp(r'^\d{10}$').hasMatch(_tin.text.trim())) {
      AppSnackBar.showError('TIN must be exactly 10 digits.');
      return;
    }

    final body = <String, dynamic>{
      'name': _name.text.trim(),
      'type': _type,
      'tin': _tin.text.trim(),
      'legalName': _legalName.text.trim(),
      'email': _email.text.trim(),
      'phone': _phone.text.trim(),
      'region': _region.text.trim().isEmpty ? '1' : _region.text.trim(),
      'wereda': _wereda.text.trim(),
      'vatNumber': _vat.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_subCity.text.trim().isNotEmpty) 'subCity': _subCity.text.trim(),
      if (_locality.text.trim().isNotEmpty) 'locality': _locality.text.trim(),
      if (_houseNumber.text.trim().isNotEmpty) 'houseNumber': _houseNumber.text.trim(),
      'settlementLevel': _settlementLevel,
    };
    await runAdminAction<OrganizationModel>(
      context,
      () => _repository.updateOrganization(_orgId, body),
      successMessage: 'Business profile saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business management')),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load profile', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                AppTextField(controller: _name, labelText: 'Display name'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _legalName, labelText: 'Legal name *'),
                const SizedBox(height: AppSizes.padding / 2),
                AdminDropdownField<String>(
                  label: 'Business type',
                  value: _type,
                  items: kOrgTypes
                      .map((o) => DropdownMenuItem(value: o, child: Text(orgTypeLabel(o))))
                      .toList(),
                  onChanged: (value) => setState(() => _type = value),
                ),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _tin, labelText: 'TIN *', keyboardType: TextInputType.number),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _vat, labelText: 'VAT number *'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _email, labelText: 'Email *', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _phone, labelText: 'Phone *', keyboardType: TextInputType.phone),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _region, labelText: 'Region *'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _wereda, labelText: 'Wereda *'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _city, labelText: 'City (optional)'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _subCity, labelText: 'Sub-city (optional)'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _locality, labelText: 'Locality (optional)'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _houseNumber, labelText: 'House number (optional)'),
                const SizedBox(height: AppSizes.padding / 2),
                AdminDropdownField<String>(
                  label: 'Settlement level',
                  value: _settlementLevel,
                  items: kSettlementLevels.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList(),
                  onChanged: (value) => setState(() => _settlementLevel = value),
                ),
                const SizedBox(height: AppSizes.padding),
                AppButton(text: 'Save business profile', onTap: _save),
              ],
            ),
    );
  }
}

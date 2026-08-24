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

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _loading = true;
  String? _error;

  final _bankName = TextEditingController();
  final _accountNumber = TextEditingController();
  final _accountHolder = TextEditingController();
  final _branchCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    _orgId = sessionOf(context)?.organizationId ?? '';
    _load();
  }

  @override
  void dispose() {
    _bankName.dispose();
    _accountNumber.dispose();
    _accountHolder.dispose();
    _branchCode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.getBankAccount(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        final bank = result.data;
        if (bank != null) {
          _bankName.text = bank.bankName;
          _accountNumber.text = bank.accountNumber;
          _accountHolder.text = bank.accountHolderName;
          _branchCode.text = bank.branchCode ?? '';
        }
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _save() async {
    final body = <String, dynamic>{
      'bankName': _bankName.text.trim(),
      'accountNumber': _accountNumber.text.trim(),
      'accountHolderName': _accountHolder.text.trim(),
      if (_branchCode.text.trim().isNotEmpty) 'branchCode': _branchCode.text.trim(),
    };
    await runAdminAction<BankAccountModel>(
      context,
      () => _repository.upsertBankAccount(_orgId, body),
      successMessage: 'Bank account saved.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bank & settlement')),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : ListView(
              padding: const EdgeInsets.all(AppSizes.padding),
              children: [
                AppTextField(controller: _bankName, labelText: 'Bank name'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _accountNumber, labelText: 'Account number'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _accountHolder, labelText: 'Account holder name'),
                const SizedBox(height: AppSizes.padding / 2),
                AppTextField(controller: _branchCode, labelText: 'Branch code (optional)'),
                const SizedBox(height: AppSizes.padding),
                AppButton(text: 'Save bank account', onTap: _save),
              ],
            ),
    );
  }
}

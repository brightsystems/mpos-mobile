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

class TaxesScreen extends StatefulWidget {
  const TaxesScreen({super.key});

  @override
  State<TaxesScreen> createState() => _TaxesScreenState();
}

class _TaxesScreenState extends State<TaxesScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _loading = true;
  String? _error;
  List<TaxModel> _taxes = const [];

  @override
  void initState() {
    super.initState();
    _orgId = sessionOf(context)?.organizationId ?? '';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.listTaxes(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _taxes = result.data ?? const [];
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _openEditor({TaxModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TaxEditor(orgId: _orgId, existing: existing),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _delete(TaxModel tax) async {
    await runAdminAction<void>(
      context,
      () => _repository.deleteTax(_orgId, tax.id),
      successMessage: 'Tax deactivated.',
    );
    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Taxes')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-taxes-fab',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add tax'),
      ),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load taxes', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : _taxes.isEmpty
          ? AppEmptyState(
              title: 'No taxes yet',
              subtitle: 'Add VAT or other tax rates for your menu items.',
              buttonText: 'Add tax',
              onTapButton: _openEditor,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: _taxes.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                itemBuilder: (context, index) {
                  final tax = _taxes[index];
                  return _TaxCard(tax: tax, onEdit: () => _openEditor(existing: tax), onDelete: () => _delete(tax));
                },
              ),
            ),
    );
  }
}

class _TaxCard extends StatelessWidget {
  const _TaxCard({required this.tax, required this.onEdit, required this.onDelete});

  final TaxModel tax;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${tax.name} · ${tax.ratePercent.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                  '${tax.code}${tax.morTaxCode != null ? ' · MOR ${tax.morTaxCode}' : ''}${tax.isActive ? '' : ' · inactive'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: onDelete, icon: Icon(Icons.delete_outline, color: colorScheme.error)),
        ],
      ),
    );
  }
}

class _TaxEditor extends StatefulWidget {
  const _TaxEditor({required this.orgId, this.existing});

  final String orgId;
  final TaxModel? existing;

  @override
  State<_TaxEditor> createState() => _TaxEditorState();
}

class _TaxEditorState extends State<_TaxEditor> {
  final _repository = getIt<AdminRepository>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _rate;
  late final TextEditingController _morCode;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _code = TextEditingController(text: widget.existing?.code ?? '');
    _rate = TextEditingController(text: widget.existing?.ratePercent.toStringAsFixed(0) ?? '');
    _morCode = TextEditingController(text: widget.existing?.morTaxCode ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _rate.dispose();
    _morCode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = {
      'name': _name.text.trim(),
      'code': _code.text.trim(),
      'ratePercent': double.tryParse(_rate.text.trim()) ?? 0,
      if (_morCode.text.trim().isNotEmpty) 'morTaxCode': _morCode.text.trim(),
      if (widget.existing != null) 'isActive': widget.existing!.isActive,
      'sortOrder': widget.existing?.sortOrder ?? 0,
    };

    final result = await runAdminAction(
      context,
      () => widget.existing == null
          ? _repository.createTax(widget.orgId, body)
          : _repository.updateTax(widget.orgId, widget.existing!.id, body),
      successMessage: 'Tax saved.',
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.padding,
        right: AppSizes.padding,
        top: AppSizes.padding,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.padding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.existing == null ? 'Add tax' : 'Edit tax',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(controller: _name, labelText: 'Name', hintText: 'VAT 15%'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _code, labelText: 'Code', hintText: 'VAT15'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(
            controller: _rate,
            labelText: 'Rate percent',
            hintText: '15',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _morCode, labelText: 'MOR tax code (optional)', hintText: 'VAT15'),
          const SizedBox(height: AppSizes.padding),
          AppButton(text: 'Save tax', onTap: _save),
        ],
      ),
    );
  }
}

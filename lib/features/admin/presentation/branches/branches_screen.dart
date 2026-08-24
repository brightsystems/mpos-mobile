import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/features/auth/domain/rbac.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _canCreate = false;
  bool _loading = true;
  String? _error;
  List<BranchModel> _branches = const [];

  @override
  void initState() {
    super.initState();
    final session = sessionOf(context);
    _orgId = session?.organizationId ?? '';
    _canCreate = session?.canCreateBranch ?? false;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repository.listBranches(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _branches = result.data ?? const [];
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _openEditor({BranchModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BranchEditor(orgId: _orgId, existing: existing),
    );
    if (saved == true) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: _canCreate
          ? FloatingActionButton.extended(
              heroTag: 'admin-branches-fab',
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add branch'),
            )
          : null,
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load branches', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : _branches.isEmpty
          ? const AppEmptyState(title: 'No branches yet')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: _branches.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  return _BranchCard(
                    branch: branch,
                    canEdit: _canCreate,
                    onEdit: () => _openEditor(existing: branch),
                  );
                },
              ),
            ),
    );
  }
}

class _BranchCard extends StatelessWidget {
  const _BranchCard({required this.branch, required this.canEdit, required this.onEdit});

  final BranchModel branch;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = [
      if (branch.city.isNotEmpty) branch.city,
      if (branch.phone.isNotEmpty) branch.phone,
      if (!branch.isActive) 'inactive',
    ].join(' · ');

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
                Text(branch.name, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (canEdit) IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
        ],
      ),
    );
  }
}

class _BranchEditor extends StatefulWidget {
  const _BranchEditor({required this.orgId, this.existing});

  final String orgId;
  final BranchModel? existing;

  @override
  State<_BranchEditor> createState() => _BranchEditorState();
}

class _BranchEditorState extends State<_BranchEditor> {
  final _repository = getIt<AdminRepository>();
  late final TextEditingController _name;
  late final TextEditingController _city;
  late final TextEditingController _phone;
  late final TextEditingController _address;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? 'Main branch');
    _city = TextEditingController(text: widget.existing?.city ?? '');
    _phone = TextEditingController(text: widget.existing?.phone ?? '');
    _address = TextEditingController(text: widget.existing?.address ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final body = <String, dynamic>{
      'name': _name.text.trim(),
      if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
      if (_phone.text.trim().isNotEmpty) 'phone': _phone.text.trim(),
      if (_address.text.trim().isNotEmpty) 'address': _address.text.trim(),
      'timezone': 'Africa/Addis_Ababa',
      if (widget.existing != null) 'isActive': widget.existing!.isActive,
    };
    final result = await runAdminAction(
      context,
      () => widget.existing == null
          ? _repository.createBranch(widget.orgId, body)
          : _repository.updateBranch(widget.existing!.id, body),
      successMessage: 'Branch saved.',
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
            widget.existing == null ? 'Add branch' : 'Edit branch',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSizes.padding),
          AppTextField(controller: _name, labelText: 'Branch name'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _city, labelText: 'City (optional)'),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _phone, labelText: 'Phone (optional)', keyboardType: TextInputType.phone),
          const SizedBox(height: AppSizes.padding / 2),
          AppTextField(controller: _address, labelText: 'Address (optional)'),
          const SizedBox(height: AppSizes.padding),
          AppButton(text: 'Save branch', onTap: _save),
        ],
      ),
    );
  }
}

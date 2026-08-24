import 'package:flutter/material.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class RolesScreen extends StatefulWidget {
  const RolesScreen({super.key});

  @override
  State<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends State<RolesScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  bool _loading = true;
  String? _error;
  List<OrganizationRoleModel> _roles = const [];
  PermissionCatalogModel? _catalog;

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
    final catalog = await _repository.getPermissionCatalog();
    final roles = await _repository.listRoles(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!roles.isSuccess) {
        _error = roles.error?.toString();
        return;
      }
      _catalog = catalog.data;
      _roles = roles.data ?? const [];
    });
  }

  Future<void> _openEditor({OrganizationRoleModel? existing}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RoleEditorSheet(
        orgId: _orgId,
        catalog: _catalog,
        existing: existing,
      ),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _delete(OrganizationRoleModel role) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete role'),
        content: Text('Delete "${role.name}"? Staff must be reassigned first.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    final result = await AppDialog.showProgress(() => _repository.deleteRole(_orgId, role.id));
    if (!mounted) return;
    if (result.isSuccess) {
      AppSnackBar.show('Role deleted.');
      _load();
    } else {
      AppSnackBar.showError(result.error?.toString() ?? 'Something went wrong.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Roles & permissions')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-roles-fab',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Add role'),
      ),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load roles', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : _roles.isEmpty
          ? AppEmptyState(
              title: 'No roles yet',
              subtitle: 'Create Pharmacist, Cashier, Doctor, or any role your business needs.',
              buttonText: 'Add role',
              onTapButton: () => _openEditor(),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: _roles.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                itemBuilder: (context, index) {
                  final role = _roles[index];
                  return ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radius),
                      side: BorderSide(color: Theme.of(context).colorScheme.surfaceContainer),
                    ),
                    title: Text(role.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${role.scope} · ${role.permissions.length} permissions'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _openEditor(existing: role)),
                        IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _delete(role)),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class _RoleEditorSheet extends StatefulWidget {
  const _RoleEditorSheet({required this.orgId, required this.catalog, this.existing});

  final String orgId;
  final PermissionCatalogModel? catalog;
  final OrganizationRoleModel? existing;

  @override
  State<_RoleEditorSheet> createState() => _RoleEditorSheetState();
}

class _RoleEditorSheetState extends State<_RoleEditorSheet> {
  final _repository = getIt<AdminRepository>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  late Set<String> _selected;
  String _scope = 'Branch';

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name.text = existing?.name ?? '';
    _description.text = existing?.description ?? '';
    _scope = existing?.scope ?? 'Branch';
    _selected = {...?existing?.permissions};
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    final permissions = _selected.toList();
    if (widget.existing == null) {
      final created = await runAdminAction(
        context,
        () => _repository.createRole(widget.orgId, {
          'name': name,
          'description': _description.text.trim(),
          'scope': _scope,
          'permissions': permissions,
        }),
        successMessage: 'Role created.',
      );
      if (created != null && mounted) Navigator.pop(context, true);
      return;
    }

    final updated = await runAdminAction(
      context,
      () async {
        await _repository.updateRole(widget.orgId, widget.existing!.id, {
          'name': name,
          'description': _description.text.trim(),
          'scope': _scope,
          'isActive': widget.existing!.isActive,
          'sortOrder': widget.existing!.sortOrder,
        });
        return _repository.setRolePermissions(widget.orgId, widget.existing!.id, permissions);
      },
      successMessage: 'Role updated.',
    );
    if (updated != null && mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final modules = widget.catalog?.modules ?? const <PermissionModuleModel>[];
    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.padding,
        right: AppSizes.padding,
        top: AppSizes.padding,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.padding,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existing == null ? 'Add role' : 'Edit role',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSizes.padding),
            AppTextField(controller: _name, labelText: 'Name'),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _description, labelText: 'Description'),
            const SizedBox(height: AppSizes.padding / 2),
            DropdownButtonFormField<String>(
              value: _scope,
              decoration: const InputDecoration(labelText: 'Scope'),
              items: const [
                DropdownMenuItem(value: 'Branch', child: Text('Branch')),
                DropdownMenuItem(value: 'Org', child: Text('Organization')),
                DropdownMenuItem(value: 'Both', child: Text('Both')),
              ],
              onChanged: (value) => setState(() => _scope = value ?? 'Branch'),
            ),
            const SizedBox(height: AppSizes.padding),
            Text('Permissions', style: Theme.of(context).textTheme.titleMedium),
            Expanded(
              child: ListView(
                children: [
                  for (final module in modules) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(module.label, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    for (final action in module.actions)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(action.label),
                        subtitle: Text(action.description),
                        value: _selected.contains(action.code),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(action.code);
                            } else {
                              _selected.remove(action.code);
                            }
                          });
                        },
                      ),
                  ],
                ],
              ),
            ),
            AppButton(text: 'Save', onTap: _save),
          ],
        ),
      ),
    );
  }
}

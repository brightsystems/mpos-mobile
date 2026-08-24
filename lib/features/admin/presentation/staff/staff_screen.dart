import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_dropdown_field.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/features/auth/domain/entities/mpos_roles.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  late String _branchId;
  bool _isOrgAdmin = false;
  bool _loading = true;
  String? _error;
  List<MemberModel> _members = const [];

  @override
  void initState() {
    super.initState();
    final session = sessionOf(context);
    _orgId = session?.organizationId ?? '';
    _branchId = session?.branchId ?? '';
    _isOrgAdmin = session?.isOrgAdmin ?? false;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = _branchId.isNotEmpty
        ? await _repository.listBranchMembers(_branchId)
        : await _repository.listOrgBranchMembers(_orgId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _members = result.data ?? const [];
      } else {
        _error = result.error?.toString();
      }
    });
  }

  Future<void> _openAssign() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AssignMemberSheet(orgId: _orgId, branchId: _branchId, isOrgAdmin: _isOrgAdmin),
    );
    if (saved == true) {
      _load();
    }
  }

  Future<void> _generateQr(MemberModel member) async {
    if (member.branchId == null || member.branchId!.isEmpty) {
      return;
    }
    final qr = await runAdminAction(context, () => _repository.generateShiftQr(member.branchId!, member.userId));
    if (qr != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (_) => _ShiftQrDialog(qr: qr),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'admin-staff-fab',
        onPressed: _openAssign,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Assign staff'),
      ),
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load staff', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : _members.isEmpty
          ? AppEmptyState(
              title: 'No staff yet',
              subtitle: 'Assign waiters, cashiers, and managers to this branch.',
              buttonText: 'Assign staff',
              onTapButton: _openAssign,
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSizes.padding),
                itemCount: _members.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                itemBuilder: (context, index) {
                  final member = _members[index];
                  return _MemberCard(
                    member: member,
                    onGenerateQr: member.canUseShiftQr ? () => _generateQr(member) : null,
                  );
                },
              ),
            ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member, this.onGenerateQr});

  final MemberModel member;
  final VoidCallback? onGenerateQr;

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
          CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Text(
              member.displayName.characters.first.toUpperCase(),
              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: AppSizes.padding / 1.5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${member.phone} · ${member.role}', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (onGenerateQr != null)
            IconButton(
              tooltip: 'Shift QR',
              onPressed: onGenerateQr,
              icon: const Icon(Icons.qr_code_2),
            ),
        ],
      ),
    );
  }
}

class _AssignMemberSheet extends StatefulWidget {
  const _AssignMemberSheet({required this.orgId, required this.branchId, required this.isOrgAdmin});

  final String orgId;
  final String branchId;
  final bool isOrgAdmin;

  @override
  State<_AssignMemberSheet> createState() => _AssignMemberSheetState();
}

class _AssignMemberSheetState extends State<_AssignMemberSheet> {
  final _repository = getIt<AdminRepository>();
  final _phone = TextEditingController();
  List<OrganizationRoleModel> _roles = const [];
  OrganizationRoleModel? _selectedRole;
  bool _loadingRoles = true;
  bool _assignOrgAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    final result = await _repository.listRoles(widget.orgId);
    if (!mounted) return;
    setState(() {
      _loadingRoles = false;
      if (result.isSuccess) {
        _roles = (result.data ?? const []).where((r) => r.isActive && r.scope != 'Org').toList();
        _selectedRole = _roles.isEmpty ? null : _roles.first;
      }
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      return;
    }
    if (_assignOrgAdmin) {
      final result = await runAdminAction(
        context,
        () => _repository.assignOrgMember(widget.orgId, phone: phone, role: MposRoles.orgAdmin),
        successMessage: 'Org admin assigned.',
      );
      if (result != null && mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }
    final role = _selectedRole;
    if (role == null) {
      return;
    }
    final result = await runAdminAction(
      context,
      () => _repository.assignBranchMember(widget.branchId, phone: phone, roleDefinitionId: role.id),
      successMessage: 'Staff assigned.',
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
          Text('Assign staff', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSizes.padding),
          AppTextField(controller: _phone, labelText: 'Phone number', keyboardType: TextInputType.phone),
          const SizedBox(height: AppSizes.padding / 2),
          if (_loadingRoles)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: AppProgressIndicator()),
            )
          else ...[
            if (_selectedRole != null)
              AdminDropdownField<OrganizationRoleModel>(
                label: 'Role',
                value: _selectedRole!,
                items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                onChanged: (value) => setState(() {
                  _assignOrgAdmin = false;
                  _selectedRole = value;
                }),
              )
            else
              const Text('No branch roles available. Create roles first.'),
            if (widget.isOrgAdmin) ...[
              const SizedBox(height: AppSizes.padding / 2),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Assign as OrgAdmin instead'),
                value: _assignOrgAdmin,
                onChanged: (value) => setState(() => _assignOrgAdmin = value),
              ),
            ],
          ],
          const SizedBox(height: AppSizes.padding),
          AppButton(text: 'Assign', onTap: _save),
        ],
      ),
    );
  }
}

class _ShiftQrDialog extends StatelessWidget {
  const _ShiftQrDialog({required this.qr});

  final ShiftQrModel qr;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.radius)),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.padding * 1.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${qr.memberName} · ${qr.role}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.padding),
            Container(
              padding: const EdgeInsets.all(AppSizes.padding),
              color: Colors.white,
              child: QrImageView(data: qr.qrPayload, size: 220, backgroundColor: Colors.white),
            ),
            const SizedBox(height: AppSizes.padding),
            Text(
              'Ask the staff member to scan this from the shift login screen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSizes.padding),
            AppButton(text: 'Done', onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }
}

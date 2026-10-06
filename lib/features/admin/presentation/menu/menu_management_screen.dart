
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:mpos_mobile/app/di/injection.dart';
import 'package:mpos_mobile/core/media/media_service.dart';
import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/admin/data/models/admin_models.dart';
import 'package:mpos_mobile/features/admin/domain/repositories/admin_repository.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_dropdown_field.dart';
import 'package:mpos_mobile/features/admin/presentation/common/admin_helpers.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  final _repository = getIt<AdminRepository>();
  late String _orgId;
  late String _sessionBranchId;
  late String _sessionBranchName;
  bool _isOrgAdmin = false;
  bool _canManageBranch = false;
  bool _loading = true;
  String? _error;

  List<BranchModel> _branches = const [];
  String _selectedBranchId = '';

  List<MenuCategoryModel> _categories = const [];
  List<AdminMenuItemModel> _items = const [];
  List<TaxModel> _taxes = const [];

  @override
  void initState() {
    super.initState();
    final session = sessionOf(context);
    _orgId = session?.organizationId ?? '';
    _sessionBranchId = session?.branchId ?? '';
    _sessionBranchName = session?.branchName ?? '';
    _isOrgAdmin = session?.isOrgAdmin ?? false;
    _canManageBranch = session?.canManageBranch ?? false;
    _selectedBranchId = _sessionBranchId;
    _load();
  }

  String get _selectedBranchName {
    if (_isOrgAdmin) {
      final match = _branches.where((b) => b.id == _selectedBranchId);
      return match.isEmpty ? '' : match.first.name;
    }
    return _sessionBranchName;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final taxesResult = await _repository.listTaxes(_orgId);

    // Org admins pick which branch's menu to view/manage; other roles are pinned
    // to their session branch. Categories are org-level for admins, else branch.
    if (_isOrgAdmin) {
      final branchesResult = await _repository.listBranches(_orgId);
      if (!mounted) return;
      _branches = branchesResult.data ?? const [];
      if (_branches.every((b) => b.id != _selectedBranchId)) {
        _selectedBranchId = _sessionBranchId.isNotEmpty && _branches.any((b) => b.id == _sessionBranchId)
            ? _sessionBranchId
            : (_branches.isNotEmpty ? _branches.first.id : '');
      }
    }

    final categoriesResult = _isOrgAdmin
        ? await _repository.listOrgCategories(_orgId)
        : await _repository.listBranchCategories(_selectedBranchId);
    final itemsResult = _selectedBranchId.isEmpty
        ? null
        : await _repository.listBranchMenu(_selectedBranchId);

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (categoriesResult.isFailure && (itemsResult?.isFailure ?? false)) {
        _error = itemsResult?.error?.toString() ?? categoriesResult.error?.toString();
        return;
      }
      _categories = categoriesResult.data ?? const [];
      _items = itemsResult?.data ?? const [];
      _taxes = taxesResult.data ?? const [];
    });
  }

  Future<void> _onBranchChanged(String branchId) async {
    if (branchId == _selectedBranchId) return;
    setState(() => _selectedBranchId = branchId);
    await _load();
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: AppSizes.padding,
          right: AppSizes.padding,
          top: AppSizes.padding / 2,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + AppSizes.padding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add category',
                    style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(sheetContext).pop(false),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: controller, labelText: 'Category name'),
            const SizedBox(height: AppSizes.padding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Expanded(
                  child: AppButton(text: 'Save', onTap: () => Navigator.of(sheetContext).pop(true)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && controller.text.trim().isNotEmpty) {
      final body = {'name': controller.text.trim(), 'sortOrder': _categories.length + 1};
      final result = await runAdminAction(
        context,
        () => _isOrgAdmin
            ? _repository.createOrgCategory(_orgId, body)
            : _repository.createBranchCategory(_selectedBranchId, body),
        successMessage: 'Category added.',
      );
      if (result != null) {
        _load();
      }
    }
  }

  Future<void> _openItemEditor({AdminMenuItemModel? existing}) async {
    if (_categories.isEmpty) {
      await _addCategory();
      if (_categories.isEmpty) return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ItemEditor(
        orgId: _orgId,
        branchId: _selectedBranchId,
        isOrgAdmin: _isOrgAdmin,
        categories: _categories,
        taxes: _taxes,
        existing: existing,
      ),
    );
    if (saved == true) {
      _load();
    }
  }

  String _taxSummary(AdminMenuItemModel item) {
    if (item.taxIds.isEmpty) return '';
    final names = item.taxIds
        .map((id) => _taxes.where((t) => t.id == id))
        .where((matches) => matches.isNotEmpty)
        .map((matches) => matches.first)
        .map((t) => '${t.name} (${t.ratePercent.toStringAsFixed(0)}%)')
        .toList();
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          if (_canManageBranch)
            IconButton(
              onPressed: _addCategory,
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Add category',
            ),
        ],
      ),
      floatingActionButton: _canManageBranch
          ? FloatingActionButton.extended(
              heroTag: 'admin-menu-fab',
              onPressed: () => _openItemEditor(),
              icon: const Icon(Icons.add),
              label: const Text('Add item'),
            )
          : null,
      body: _loading
          ? const Center(child: AppProgressIndicator())
          : _error != null
          ? AppEmptyState(title: 'Could not load menu', subtitle: _error, buttonText: 'Retry', onTapButton: _load)
          : Column(
              children: [
                _MenuHeader(
                  branchName: _selectedBranchName,
                  showBranchSelector: _isOrgAdmin && _branches.isNotEmpty,
                  branches: _branches,
                  selectedBranchId: _selectedBranchId,
                  onBranchChanged: _onBranchChanged,
                ),
                Expanded(
                  child: _items.isEmpty
                      ? AppEmptyState(
                          title: 'No menu items yet',
                          subtitle: _canManageBranch
                              ? 'Add categories and items your staff can sell.'
                              : 'No items have been added for this branch yet.',
                          buttonText: _canManageBranch ? 'Add item' : null,
                          onTapButton: _canManageBranch ? _openItemEditor : null,
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.all(AppSizes.padding),
                            itemCount: _items.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSizes.padding / 2),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return _ItemCard(
                                item: item,
                                taxSummary: _taxSummary(item),
                                canEdit: _canManageBranch,
                                onEdit: () => _openItemEditor(existing: item),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({
    required this.branchName,
    required this.showBranchSelector,
    required this.branches,
    required this.selectedBranchId,
    required this.onBranchChanged,
  });

  final String branchName;
  final bool showBranchSelector;
  final List<BranchModel> branches;
  final String selectedBranchId;
  final ValueChanged<String> onBranchChanged;

  @override
  Widget build(BuildContext context) {
    final subtitle = branchName.isNotEmpty
        ? 'Categories and items for $branchName.'
        : 'Categories and items for the selected branch.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSizes.padding, AppSizes.padding, AppSizes.padding, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline)),
          if (showBranchSelector) ...[
            const SizedBox(height: AppSizes.padding),
            AdminDropdownField<String>(
              label: 'Branch',
              value: branches.any((b) => b.id == selectedBranchId) ? selectedBranchId : branches.first.id,
              items: branches.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))).toList(),
              onChanged: onBranchChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item, required this.taxSummary, required this.canEdit, required this.onEdit});

  final AdminMenuItemModel item;
  final String taxSummary;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSizes.padding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSizes.radius),
        border: Border.all(color: colorScheme.surfaceContainer),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumb(imageUrl: item.imageUrl),
          const SizedBox(width: AppSizes.padding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    if (!item.isAvailable) const _AvailabilityTag(),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.categoryName} Â· ${CurrencyFormatter.format(item.price)}',
                  style: textTheme.bodySmall,
                ),
                if (taxSummary.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(taxSummary, style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                ],
                if ((item.sku ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('SKU: ${item.sku}', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
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

class _Thumb extends StatelessWidget {
  const _Thumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final url = imageUrl ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSizes.radius),
      child: Container(
        width: 52,
        height: 52,
        color: colorScheme.surfaceContainerHighest,
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, size: 20, color: colorScheme.outline),
              )
            : Icon(Icons.image_outlined, size: 20, color: colorScheme.outline),
      ),
    );
  }
}

class _AvailabilityTag extends StatelessWidget {
  const _AvailabilityTag();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Hidden',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ItemEditor extends StatefulWidget {
  const _ItemEditor({
    required this.orgId,
    required this.branchId,
    required this.isOrgAdmin,
    required this.categories,
    required this.taxes,
    this.existing,
  });

  final String orgId;
  final String branchId;
  final bool isOrgAdmin;
  final List<MenuCategoryModel> categories;
  final List<TaxModel> taxes;
  final AdminMenuItemModel? existing;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  final _repository = getIt<AdminRepository>();
  final _media = getIt<MediaService>();
  final _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _sku;
  late final TextEditingController _imageUrl;
  late final TextEditingController _initialStock;
  late String _categoryId;
  late Set<String> _taxIds;
  String? _hsnCode;
  List<HsnCodeModel> _hsnCodes = const [];
  bool _trackInventory = false;
  bool _isActive = true;
  bool _uploading = false;

  bool get _isEdit => widget.existing != null;

  Future<void> _loadHsnCodes() async {
    final result = await _repository.listHsnCodes();
    if (!mounted || !result.isSuccess) return;
    setState(() => _hsnCodes = result.data ?? const []);
  }

  double? get _selectedHsnRate {
    final code = _hsnCode;
    if (code == null || code.isEmpty) return null;
    for (final hsn in _hsnCodes) {
      if (hsn.code == code) return hsn.ratePercent;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _name = TextEditingController(text: existing?.name ?? '');
    _price = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(2) : '');
    _description = TextEditingController(text: existing?.description ?? '');
    _sku = TextEditingController(text: existing?.sku ?? '');
    _imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    _initialStock = TextEditingController();
    _categoryId = existing?.categoryId ?? widget.categories.first.id;
    if (!widget.categories.any((c) => c.id == _categoryId)) {
      _categoryId = widget.categories.first.id;
    }
    _taxIds = {...?existing?.taxIds};
    _hsnCode = existing?.harmonizationCode;
    _trackInventory = existing?.trackInventory ?? false;
    _isActive = existing?.isAvailable ?? true;
    _loadHsnCodes();

    // New items default to VAT15 (or the first non-exempt tax), matching the web admin.
    if (existing == null && _taxIds.isEmpty && widget.taxes.isNotEmpty) {
      final vat = widget.taxes.where((t) => t.code.toUpperCase() == 'VAT15');
      final nonExempt = widget.taxes.where((t) => !_isExemptTax(t));
      final fallback = nonExempt.isNotEmpty ? nonExempt.first : widget.taxes.first;
      _taxIds = {(vat.isNotEmpty ? vat.first : fallback).id};
    }

    // Exempt is exclusive â€” drop any other selections if Exempt is already set.
    final exempt = _exemptTax;
    if (exempt != null && _taxIds.contains(exempt.id) && _taxIds.length > 1) {
      _taxIds = {exempt.id};
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _sku.dispose();
    _imageUrl.dispose();
    _initialStock.dispose();
    super.dispose();
  }

  Future<void> _pickAndUpload() async {
    if (widget.orgId.isEmpty) {
      AppSnackBar.showError('No organization on this session.');
      return;
    }

    final XFile? file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1280, imageQuality: 82);
    if (file == null) {
      return;
    }

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final contentType = file.mimeType ?? _contentTypeFor(file.name);
      final url = await _media.uploadMenuImage(
        bytes: bytes,
        fileName: file.name,
        contentType: contentType,
        organizationId: widget.orgId,
      );
      if (!mounted) return;
      setState(() => _imageUrl.text = url);
      AppSnackBar.show('Photo uploaded.');
    } catch (e) {
      AppSnackBar.showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  String _contentTypeFor(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  bool _isExemptTax(TaxModel tax) {
    final code = tax.code.trim().toUpperCase();
    final mor = tax.morTaxCode?.trim().toUpperCase() ?? '';
    return code == 'EXEMPT' || mor == 'EXEMPT';
  }

  TaxModel? get _exemptTax {
    final matches = widget.taxes.where(_isExemptTax);
    return matches.isEmpty ? null : matches.first;
  }

  bool get _exemptSelected {
    final exempt = _exemptTax;
    return exempt != null && _taxIds.contains(exempt.id);
  }

  void _onTaxSelected(TaxModel tax, bool selected) {
    setState(() {
      if (_isExemptTax(tax)) {
        if (selected) {
          _taxIds
            ..clear()
            ..add(tax.id);
        } else {
          _taxIds.remove(tax.id);
        }
        return;
      }

      if (selected) {
        final exempt = _exemptTax;
        if (exempt != null) {
          _taxIds.remove(exempt.id);
        }
        _taxIds.add(tax.id);
      } else {
        _taxIds.remove(tax.id);
      }
    });
  }

  bool _validateTaxes() {
    if (_exemptSelected && _taxIds.length > 1) {
      AppSnackBar.showError('Exempt cannot be combined with other taxes.');
      return false;
    }
    final fiscalCount = widget.taxes
        .where((t) => _taxIds.contains(t.id) && (t.morTaxCode?.trim().isNotEmpty ?? false))
        .length;
    if (fiscalCount > 1) {
      AppSnackBar.showError('At most one MoR (fiscal) tax can be assigned.');
      return false;
    }
    return true;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      AppSnackBar.showError('Item name is required.');
      return;
    }
    if (!_validateTaxes()) {
      return;
    }

    final body = <String, dynamic>{
      'categoryId': _categoryId,
      'name': _name.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      if (_description.text.trim().isNotEmpty) 'description': _description.text.trim(),
      if (_sku.text.trim().isNotEmpty) 'sku': _sku.text.trim(),
      if (_imageUrl.text.trim().isNotEmpty) 'imageUrl': _imageUrl.text.trim(),
      'taxIds': _taxIds.toList(),
      'trackInventory': _trackInventory,
      'harmonizationCode': (_hsnCode?.isEmpty ?? true) ? null : _hsnCode,
    };

    if (_isEdit) {
      body['isActive'] = _isActive;
    } else if (_trackInventory && _initialStock.text.trim().isNotEmpty) {
      body['initialStock'] = double.tryParse(_initialStock.text.trim()) ?? 0;
    }

    final result = await runAdminAction(
      context,
      () {
        if (_isEdit) {
          return _repository.updateItem(widget.existing!.id, body);
        }
        return widget.isOrgAdmin
            ? _repository.createOrgItem(widget.orgId, body)
            : _repository.createBranchItem(widget.branchId, body);
      },
      successMessage: 'Item saved.',
    );
    if (result != null && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final exemptSelected = _exemptSelected;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.padding,
        right: AppSizes.padding,
        top: AppSizes.padding / 2,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.padding,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isEdit ? 'Edit item' : 'Add item',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _name, labelText: 'Name'),
            const SizedBox(height: AppSizes.padding / 2),
            AdminDropdownField<String>(
              label: 'Category',
              value: _categoryId,
              items: widget.categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _price, labelText: 'Price', keyboardType: TextInputType.number),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _description, labelText: 'Description (optional)', maxLines: 2),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _sku, labelText: 'SKU (optional)'),
            const SizedBox(height: AppSizes.padding),
            _ImagePickerField(
              imageUrl: _imageUrl.text,
              uploading: _uploading,
              onPick: _uploading ? null : _pickAndUpload,
              onClear: _imageUrl.text.isEmpty ? null : () => setState(() => _imageUrl.clear()),
            ),
            const SizedBox(height: AppSizes.padding / 2),
            AppTextField(controller: _imageUrl, labelText: 'Image URL', onChanged: (_) => setState(() {})),
            if (widget.taxes.isNotEmpty) ...[
              const SizedBox(height: AppSizes.padding),
              Text('Taxes', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSizes.padding / 2),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.taxes.map((tax) {
                  final isExempt = _isExemptTax(tax);
                  final selected = _taxIds.contains(tax.id);
                  final disabled = exemptSelected && !isExempt;
                  return FilterChip(
                    label: Text('${tax.name} (${tax.ratePercent.toStringAsFixed(0)}%)'),
                    selected: selected,
                    onSelected: disabled ? null : (value) => _onTaxSelected(tax, value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
              Text(
                exemptSelected
                    ? 'Exempt is selected â€” other taxes are disabled.'
                    : 'Selecting Exempt clears other taxes. At most one MoR tax can be assigned.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
            const SizedBox(height: AppSizes.padding),
            AdminDropdownField<String>(
              label: 'HSN code (excise)',
              value: (_hsnCode != null && _hsnCodes.any((h) => h.code == _hsnCode)) ? _hsnCode! : '',
              items: [
                const DropdownMenuItem(value: '', child: Text('None')),
                for (final hsn in _hsnCodes)
                  DropdownMenuItem(
                    value: hsn.code,
                    child: Text(
                      '${hsn.code} â€” ${hsn.ratePercent.toStringAsFixed(hsn.ratePercent % 1 == 0 ? 0 : 1)}%'
                      '${(hsn.description?.isNotEmpty ?? false) ? ' Â· ${hsn.description}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) => setState(() => _hsnCode = value.isEmpty ? null : value),
            ),
            if (_selectedHsnRate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Excise ${_selectedHsnRate!.toStringAsFixed(_selectedHsnRate! % 1 == 0 ? 0 : 1)}% will apply automatically.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
            const SizedBox(height: AppSizes.padding / 2),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Track inventory'),
              value: _trackInventory,
              onChanged: (v) => setState(() => _trackInventory = v),
            ),
            if (!_isEdit && _trackInventory)
              AppTextField(controller: _initialStock, labelText: 'Initial stock', keyboardType: TextInputType.number),
            if (_isEdit)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Available'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            const SizedBox(height: AppSizes.padding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSizes.padding / 2),
                Expanded(
                  child: AppButton(text: 'Save item', onTap: _save),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePickerField extends StatelessWidget {
  const _ImagePickerField({required this.imageUrl, required this.uploading, this.onPick, this.onClear});

  final String imageUrl;
  final bool uploading;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl.trim().isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radius),
          child: Container(
            width: 72,
            height: 72,
            color: colorScheme.surfaceContainerHighest,
            child: uploading
                ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                : hasImage
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: colorScheme.outline),
                  )
                : Icon(Icons.image_outlined, color: colorScheme.outline),
          ),
        ),
        const SizedBox(width: AppSizes.padding),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Product photo', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Uploads on Save; only the URL is saved.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
              ),
              const SizedBox(height: AppSizes.padding / 2),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_outlined, size: 18),
                    label: Text(hasImage ? 'Replace' : 'Upload'),
                  ),
                  if (onClear != null) ...[
                    const SizedBox(width: 8),
                    TextButton(onPressed: onClear, child: const Text('Remove')),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

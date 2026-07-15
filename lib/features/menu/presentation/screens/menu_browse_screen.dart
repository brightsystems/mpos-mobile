import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';
import 'package:mpos_mobile/shared/widgets/menu_product_image.dart';

class MenuBrowseScreen extends StatefulWidget {
  const MenuBrowseScreen({super.key});

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<PosBloc>();
        if (bloc.state.menuItems.isEmpty) {
          bloc.add(const PosStarted());
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.status == PosStatus.loading && state.menuItems.isEmpty) {
          return const Center(child: AppProgressIndicator());
        }

        if (state.menuItems.isEmpty) {
          return AppEmptyState(
            subtitle: 'No menu items loaded.',
            buttonText: 'Refresh',
            onTapButton: () => context.read<PosBloc>().add(const PosRefreshRequested()),
          );
        }

        final grouped = <String, List<MenuItemEntity>>{};

        for (final item in state.filteredItems) {
          grouped.putIfAbsent(item.categoryName, () => []).add(item);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSizes.padding),
          children: [
            AppTextField(
              controller: _searchController,
              hintText: 'Search menu...',
              type: AppTextFieldType.search,
              textInputAction: TextInputAction.search,
              onChanged: (value) => context.read<PosBloc>().add(PosSearchChanged(value)),
              onTapClearButton: () => context.read<PosBloc>().add(const PosSearchChanged('')),
            ),
            const SizedBox(height: AppSizes.padding),
            for (final entry in grouped.entries) ...[
              Text(entry.key, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSizes.padding / 2),
              ...entry.value.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSizes.padding / 2),
                  child: ListTile(
                    leading: MenuProductImage(
                      imageUrl: item.imageUrl,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (item.description != null) ...[
                          Text(item.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          [
                            if (item.sku != null) item.sku,
                            if (item.trackInventory) 'Stock ${item.stockDisplay}',
                            item.taxLabel,
                          ].whereType<String>().join(' · '),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      CurrencyFormatter.format(item.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                );
              }),
              const SizedBox(height: AppSizes.padding),
            ],
          ],
        );
      },
    );
  }
}

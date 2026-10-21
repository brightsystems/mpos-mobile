import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'package:mpos_mobile/core/theme/app_sizes.dart';
import 'package:mpos_mobile/core/utilities/currency_formatter.dart';
import 'package:mpos_mobile/features/pos/domain/entities/menu_item_entity.dart';
import 'package:mpos_mobile/features/pos/domain/entities/order_entity.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_bloc.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_event.dart';
import 'package:mpos_mobile/features/pos/presentation/bloc/pos_state.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/shift_gate.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/checkout_dialogs.dart';
import 'package:mpos_mobile/features/pos/presentation/screens/components/payment_success_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_button.dart';
import 'package:mpos_mobile/shared/widgets/app_dialog.dart';
import 'package:mpos_mobile/shared/widgets/app_empty_state.dart';
import 'package:mpos_mobile/shared/widgets/app_progress_indicator.dart';
import 'package:mpos_mobile/shared/widgets/app_snack_bar.dart';
import 'package:mpos_mobile/shared/widgets/app_text_field.dart';
import 'package:mpos_mobile/shared/widgets/menu_product_image.dart';
import 'package:mpos_mobile/shared/widgets/order_card.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _panelController = PanelController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<PosBloc>().add(const PosStarted());
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    context.read<PosBloc>().add(const PosRefreshRequested());
  }

  @override
  Widget build(BuildContext context) {
    // Selling needs an open shift with a live MoR session on its register (as on the web POS).
    return ShiftGate(child: _buildPos(context));
  }

  Widget _buildPos(BuildContext context) {
    return BlocConsumer<PosBloc, PosState>(
      listenWhen: (previous, current) =>
          current.errorMessage != previous.errorMessage ||
          (current.status == PosStatus.success && current.lastOrder != null),
      listener: (context, state) {
        if (state.errorMessage != null) {
          AppSnackBar.show(state.errorMessage!);
        }

        if (state.status == PosStatus.success && state.lastOrder != null && state.lastOrder!.isClosed) {
          PaymentSuccessDialog.show(
            context: context,
            order: state.lastOrder!,
            invoice: state.lastInvoice,
            receipt: state.businessProfile?.receipt,
            vocabulary: state.vocabulary,
            onDone: () => context.read<PosBloc>().add(const PosCheckoutDismissed()),
          );
        }
      },
      builder: (context, state) {
        final hasOpenTicket = state.openOrders.isNotEmpty;
        final menuBody = _PosMenuBody(
          scrollController: _scrollController,
          searchController: _searchController,
          onRefresh: _onRefresh,
          hasCartOverlay: hasOpenTicket,
        );

        if (!hasOpenTicket) {
          return Scaffold(body: menuBody);
        }

        return Scaffold(
          body: SlidingUpPanel(
            controller: _panelController,
            minHeight: 88,
            maxHeight: AppSizes.screenHeight(context) - AppSizes.appBarHeight() - AppSizes.viewPadding(context).top,
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
                offset: const Offset(0, -4),
                blurRadius: 12,
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radius * 2),
              topRight: Radius.circular(AppSizes.radius * 2),
            ),
            body: menuBody,
            header: _PosCartHeader(panelController: _panelController),
            panel: _PosCartPanel(panelController: _panelController),
            footer: _PosCartFooter(panelController: _panelController),
            onPanelOpened: () => context.read<PosBloc>().add(const PosPanelExpandedChanged(true)),
            onPanelClosed: () => context.read<PosBloc>().add(const PosPanelExpandedChanged(false)),
          ),
        );
      },
    );
  }
}

class _PosMenuBody extends StatelessWidget {
  const _PosMenuBody({
    required this.scrollController,
    required this.searchController,
    required this.onRefresh,
    required this.hasCartOverlay,
  });

  final ScrollController scrollController;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;
  final bool hasCartOverlay;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final items = state.filteredItems;
        final isLoading = state.status == PosStatus.loading && state.menuItems.isEmpty;

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            controller: scrollController,
            physics: (items.isEmpty && !isLoading) ? const NeverScrollableScrollPhysics() : null,
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                automaticallyImplyLeading: false,
                collapsedHeight: 70,
                titleSpacing: 0,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding),
                  child: AppTextField(
                    controller: searchController,
                    hintText: 'Search menu...',
                    type: AppTextFieldType.search,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) => context.read<PosBloc>().add(PosSearchChanged(value)),
                    onTapClearButton: () => context.read<PosBloc>().add(const PosSearchChanged('')),
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(padding: EdgeInsets.only(bottom: 140), child: AppProgressIndicator()),
                )
              else if (items.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: hasCartOverlay ? 140 : AppSizes.padding),
                    child: AppEmptyState(
                      subtitle: state.status == PosStatus.failure
                          ? 'Could not load menu. Pull to refresh.'
                          : 'No menu items available for this branch.',
                      buttonText: 'Refresh',
                      onTapButton: () => context.read<PosBloc>().add(const PosRefreshRequested()),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSizes.padding, 2, AppSizes.padding, AppSizes.padding),
                  sliver: SliverGrid.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 200,
                      childAspectRatio: 1 / 1.5,
                      crossAxisSpacing: AppSizes.padding / 2,
                      mainAxisSpacing: AppSizes.padding / 2,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _PosMenuItemCard(item: items[index]),
                  ),
                ),
              SliverPadding(padding: EdgeInsets.only(bottom: hasCartOverlay ? 140 : AppSizes.padding)),
            ],
          ),
        );
      },
    );
  }
}

class _PosMenuItemCard extends StatelessWidget {
  const _PosMenuItemCard({required this.item});

  final MenuItemEntity item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.isOutOfStock ? null : () => _showAddDialog(context, item),
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(width: 0.5, color: Theme.of(context).colorScheme.surfaceContainerHighest),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: MenuProductImage(imageUrl: item.imageUrl, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(item.price),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (item.trackInventory)
              Text(
                '${item.categoryName} · Stock ${item.stockDisplay}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, MenuItemEntity item) {
    final bloc = context.read<PosBloc>();
    final activeTable = bloc.state.activeTableNumber;
    final isWalkIn = activeTable == null || activeTable == 'Walk-in';
    final tableController = TextEditingController(text: isWalkIn ? '' : activeTable);
    var quantity = 1;

    AppDialog.show(
      title: 'Add to cart',
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OrderCard(
                name: item.name,
                imageUrl: item.imageUrl ?? '',
                stock: item.stockDisplay,
                price: item.price.round(),
                initialQuantity: quantity,
                onChangedQuantity: (value) => quantity = value,
              ),
              const SizedBox(height: AppSizes.padding),
              if (bloc.state.businessProfile?.showServicePoints ?? true)
                AppTextField(
                  controller: tableController,
                  labelText: '${bloc.state.vocabulary.servicePoint} (optional)',
                  hintText: 'Leave empty for ${bloc.state.walkInLabel().toLowerCase()}',
                  keyboardType: TextInputType.text,
                ),
            ],
          );
        },
      ),
      rightButtonText: 'Add',
      leftButtonText: 'Cancel',
      onTapRightButton: (dialogContext) {
        final tableNumber = (bloc.state.businessProfile?.showServicePoints ?? true) ? tableController.text.trim() : '';
        bloc.add(PosItemAdded(item, quantity == 0 ? 1 : quantity, tableNumber: tableNumber));
        dialogContext.pop();
      },
    );
  }
}

class _PosCartHeader extends StatelessWidget {
  const _PosCartHeader({required this.panelController});

  final PanelController panelController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final activeTicket = state.activeTicket;

        return Container(
          width: AppSizes.screenWidth(context),
          padding: const EdgeInsets.fromLTRB(
            AppSizes.padding,
            AppSizes.padding / 2,
            AppSizes.padding,
            AppSizes.padding / 1.5,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.surfaceContainer)),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppSizes.radius * 2),
              topRight: Radius.circular(AppSizes.radius * 2),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.54),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(height: AppSizes.padding / 1.5),
              if (state.tables.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: state.tables.map((table) {
                      final isSelected = table.tableNumber == (activeTicket?.tableNumber ?? 'Walk-in');
                      final selectedTicket =
                          table.tickets.where((ticket) => !ticket.isClosed).fold<OrderEntity?>(null, (latest, ticket) {
                            if (latest == null) {
                              return ticket;
                            }

                            final latestTime = latest.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                            final ticketTime = ticket.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                            return ticketTime.isAfter(latestTime) ? ticket : latest;
                          }) ??
                          table.tickets.first;

                      return Padding(
                        padding: const EdgeInsets.only(right: AppSizes.padding / 2),
                        child: ChoiceChip(
                          label: Text(state.servicePointChipLabel(table.tableNumber)),
                          selected: isSelected,
                          onSelected: (_) {
                            context.read<PosBloc>().add(PosTicketSelected(selectedTicket.id));
                            if (!panelController.isPanelOpen) {
                              panelController.open();
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSizes.padding / 1.5),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeTicket == null
                              ? 'Current cart'
                              : '${state.displayServicePoint(activeTicket.tableNumber)} · ${activeTicket.ticketNumber}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          activeTicket == null
                              ? 'Search items and add to cart.'
                              : '${state.cartLines.length} items · ${CurrencyFormatter.format(state.cartTotal)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.padding / 2),
                  if (state.businessProfile?.showServicePoints ?? true)
                    AppButton(
                      height: 26,
                      borderRadius: BorderRadius.circular(4),
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
                      buttonColor: Theme.of(context).colorScheme.surface,
                      borderColor: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.primary,
                      text: activeTicket == null
                          ? '${state.vocabulary.servicePoint} optional'
                          : 'Edit ${state.vocabulary.servicePoint.toLowerCase()}',
                      onTap: () => _showTableDialog(context, activeTicket?.tableNumber),
                    ),
                  if (state.businessProfile?.showServicePoints ?? true) const SizedBox(width: AppSizes.padding / 2),
                  AppButton(
                    height: 26,
                    borderRadius: BorderRadius.circular(4),
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.padding / 2),
                    buttonColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.32),
                    borderColor: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.32),
                    enabled: state.cartLines.isNotEmpty,
                    onTap: () {
                      context.read<PosBloc>().add(const PosCartCleared());
                      panelController.close();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear_rounded, size: 12, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: AppSizes.padding / 4),
                        Text(
                          'Close',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showTableDialog(BuildContext context, String? currentTableNumber) {
    final state = context.read<PosBloc>().state;
    final activeTicket = state.activeTicket;

    if (activeTicket == null) {
      AppSnackBar.show('Add an item to the cart first.');
      return;
    }

    final isWalkIn = (currentTableNumber ?? 'Walk-in') == 'Walk-in';
    final controller = TextEditingController(text: isWalkIn ? '' : currentTableNumber ?? '');
    final servicePoint = state.vocabulary.servicePoint;

    AppDialog.show(
      title: 'Assign ${servicePoint.toLowerCase()}',
      leftButtonText: 'Cancel',
      rightButtonText: 'Save',
      child: AppTextField(
        controller: controller,
        labelText: '$servicePoint (optional)',
        hintText: 'Leave empty for ${state.walkInLabel().toLowerCase()}',
      ),
      onTapRightButton: (dialogContext) {
        context.read<PosBloc>().add(PosActiveTicketTableChanged(controller.text.trim()));
        dialogContext.pop();
      },
    );
  }
}

class _PosCartPanel extends StatelessWidget {
  const _PosCartPanel({required this.panelController});

  final PanelController panelController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        if (state.activeTicket == null) {
          return SizedBox(
            height: 200,
            child: AppEmptyState(
              title: 'No ${state.vocabulary.ticket.toLowerCase()}',
              subtitle: state.vocabulary.newOrderAction,
            ),
          );
        }

        if (state.cartLines.isEmpty) {
          return const SizedBox(
            height: 200,
            child: AppEmptyState(title: 'Empty', subtitle: 'No unpaid items in ticket'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(top: 76, bottom: AppSizes.padding),
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            children: [
              SizedBox(
                height: AppSizes.screenHeight(context) - 272,
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppSizes.padding),
                  itemCount: state.cartLines.length,
                  itemBuilder: (context, index) {
                    final line = state.cartLines[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.padding),
                      child: GestureDetector(
                        onLongPress: () => _showLineDiscountDialog(context, line),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OrderCard(
                              name: line.name,
                              imageUrl: line.imageUrl ?? '',
                              stock: line.trackInventory ? (line.stockOnHand ?? 0).floor() : 999,
                              price: line.unitPrice.round(),
                              initialQuantity: line.remainingQuantity.round(),
                              onChangedQuantity: (value) {
                                context.read<PosBloc>().add(
                                  PosLineQuantityChanged(line.id, value + line.paidQuantity.round()),
                                );
                              },
                              onTapRemove: () {
                                context.read<PosBloc>().add(PosLineRemoved(line.id));

                                if (state.cartLines.length == 1) {
                                  panelController.close();
                                }
                              },
                            ),
                            if (line.discount > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 2, right: 4),
                                child: Text(
                                  'Discount −${CurrencyFormatter.format(line.discount)} (long-press to edit)',
                                  textAlign: TextAlign.end,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSizes.padding),
                child: _CartSummary(order: state.activeTicket!),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PosCartFooter extends StatelessWidget {
  const _PosCartFooter({required this.panelController});

  final PanelController panelController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PosBloc, PosState>(
      builder: (context, state) {
        final isExpanded = state.isPanelExpanded;
        final isCheckingOut = state.status == PosStatus.checkingOut;
        final activeTicket = state.activeTicket;

        return Container(
          width: AppSizes.screenWidth(context),
          padding: const EdgeInsets.fromLTRB(AppSizes.padding, 0, AppSizes.padding, AppSizes.padding),
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          child: Row(
            children: [
              if (isExpanded)
                Expanded(
                  child: AppButton(
                    text: 'Back',
                    buttonColor: Theme.of(context).colorScheme.surface,
                    borderColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.primary,
                    onTap: () => panelController.close(),
                  ),
                ),
              if (isExpanded) const SizedBox(width: AppSizes.padding / 2),
              Expanded(
                flex: isExpanded ? 1 : 2,
                child: AppButton(
                  fontSize: 12,
                  text: isCheckingOut
                      ? 'Processing...'
                      : isExpanded
                      ? (activeTicket?.isDraft ?? true ? 'Checkout' : 'Pay')
                      : state.cartLines.isEmpty
                      ? 'Cart'
                      : activeTicket == null
                      ? '${state.cartLines.length} items · ${CurrencyFormatter.format(state.cartTotal)}'
                      : '${state.displayServicePoint(state.activeTableNumber)} · ${CurrencyFormatter.format(state.cartTotal)}',
                  enabled: !isCheckingOut,
                  onTap: () {
                    if (activeTicket == null) {
                      AppSnackBar.show('Add items to the cart first.');
                    } else if (isExpanded) {
                      startCheckout(context, activeTicket);
                    } else {
                      panelController.open();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

void _showLineDiscountDialog(BuildContext context, OrderLineEntity line) {
  final bloc = context.read<PosBloc>();
  final discountController = TextEditingController(text: line.discount > 0 ? line.discount.toStringAsFixed(2) : '');
  final maxDiscount = line.unitPrice * line.quantity;

  AppDialog.show(
    title: 'Line discount',
    leftButtonText: 'Cancel',
    child: StatefulBuilder(
      builder: (context, setState) {
        final parsed = double.tryParse(discountController.text.trim());
        final entered = discountController.text.trim();
        final valid = entered.isEmpty || (parsed != null && parsed >= 0 && parsed <= maxDiscount);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(line.name, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSizes.padding / 2),
            Text('Line value ${CurrencyFormatter.format(maxDiscount)}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppSizes.padding),
            AppTextField(
              controller: discountController,
              labelText: 'Discount amount (ETB)',
              hintText: '0.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
            ),
            if (!valid)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Enter an amount between 0 and ${CurrencyFormatter.format(maxDiscount)}.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: AppSizes.padding * 1.5),
            AppButton(
              text: 'Apply discount',
              enabled: valid,
              onTap: () {
                final amount = double.tryParse(discountController.text.trim()) ?? 0;
                bloc.add(PosLineDiscountChanged(line.id, amount));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    ),
  );
}

/// Order amounts as the API calculates them (same figures as the web POS).
class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.order});

  final OrderEntity order;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final showBreakdown = order.withholdingAmount > 0 || order.paidAmount > 0;

    Widget row(String label, double amount, {bool bold = false}) {
      final style = (bold ? textTheme.bodyMedium : textTheme.labelSmall)?.copyWith(
        fontWeight: bold ? FontWeight.bold : null,
      );
      return Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style),
            Text(CurrencyFormatter.format(amount), style: style),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row('Subtotal (excl. tax)', order.subtotal),
        row('Taxes', order.taxAmount),
        row('Total', order.totalAmount, bold: !showBreakdown),
        if (order.withholdingAmount > 0) row('Withholding (if the buyer withholds)', order.withholdingAmount),
        if (order.paidAmount > 0) row('Paid so far', order.paidAmount),
        if (showBreakdown) row('To pay', order.remainingTotal, bold: true),
        if (!order.isDraft)
          Text(
            order.isCreditSale ? 'Credit sale · invoice registered' : 'Cash sale · invoice registered',
            textAlign: TextAlign.end,
            style: textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
      ],
    );
  }
}

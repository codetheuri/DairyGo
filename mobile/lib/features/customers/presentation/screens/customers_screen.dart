import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/pagination/paged_list_notifier.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/customer_models.dart';
import '../controllers/customer_controller.dart';
import '../widgets/add_customer_dialog.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/widgets/skeleton.dart';

/// Customers (coolers, processors, hotels, shops, individuals). Collectors can
/// search and add; admins and board members also see what each customer owes.
class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final seesBalances = user?.isExecutive ?? false; // admins and board members
    final canAdd =
        (user?.isSaccoAdmin ?? false) ||
        !(user?.isExecutive ?? false); // not board
    final customersAsync = ref.watch(customersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Customers',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text(
                'Add Customer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                final created = await AddCustomerDialog.show(context);
                if (created != null && context.mounted) {
                  context.push('/customers/${created.id}');
                }
              },
            )
          : null,
      body: ReadableWidth(
        maxWidth: 900,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextFormField(
                // The list remembers its search between visits, so show it.
                initialValue: ref.read(customerSearchProvider),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    ref.read(customerSearchProvider.notifier).state = v.trim();
                  });
                },
              ),
            ),
            if (seesBalances) const _TotalOwedBanner(),
            Expanded(
              child: customersAsync.when(
                data: (paged) {
                  final customers = paged.items;
                  if (customers.isEmpty) {
                    return const EmptyStateWidget(
                      title: 'No customers yet',
                      description:
                          'Customers are added when recording a sale, or with the button below.',
                      icon: Icons.storefront_outlined,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async => ref.refresh(customersListProvider),
                    child: ListView.separated(
                      // Bottom space so the floating button never covers the last row.
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                      itemCount: customers.length + (paged.showFooter ? 1 : 0),
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (_, i) => i == customers.length
                          ? PagedListFooter(
                              list: paged,
                              onLoadMore: () => ref
                                  .read(customersListProvider.notifier)
                                  .loadMore(),
                            )
                          : _CustomerTile(customer: customers[i]),
                    ),
                  );
                },
                loading: () => const ListSkeleton(),
                error: (e, _) => ErrorView(
                  message: e.toString().replaceAll('Exception: ', ''),
                  onRetry: () => ref.refresh(customersListProvider.future),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalOwedBanner extends ConsumerWidget {
  const _TotalOwedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balances = ref.watch(customerBalancesProvider).valueOrNull;
    if (balances == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Customers owe KES ${balances.totalOwed.toStringAsFixed(2)} '
        '(${balances.balances.where((b) => b.balance > 0).length} with a balance)',
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  final CustomerModel customer;

  const _CustomerTile({required this.customer});

  @override
  Widget build(BuildContext context) {
    final balance = customer.balance;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => context.push('/customers/${customer.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.accentMint,
                foregroundColor: AppColors.primary,
                child: Icon(
                  customer.customerType == 'COOLER'
                      ? Icons.ac_unit_rounded
                      : Icons.storefront_rounded,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      [
                        customerTypeLabel(customer.customerType),
                        if (customer.phone != null) customer.phone!,
                        if (!customer.isActive) 'INACTIVE',
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (balance != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: balance > 0
                            ? AppColors.error
                            : AppColors.success,
                      ),
                    ),
                    Text(
                      balance > 0
                          ? 'owes'
                          : (balance < 0 ? 'in credit' : 'settled'),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/money.dart';
import '../payout_providers.dart';

/// The farmer's account at a glance on their profile; opens the account.
class FarmerAccountCard extends ConsumerWidget {
  final String memberId;

  const FarmerAccountCard({super.key, required this.memberId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(farmerAccountProvider(memberId)).valueOrNull;
    final String line;
    if (account == null) {
      line = 'Advances, charges, deductions, shares and statement';
    } else {
      line = [
        account.balance < 0
            ? 'Owes ${kes(-account.balance, cents: false)}'
            : 'Balance ${kes(account.balance, cents: false)}',
        'Shares ${kes(account.shares, cents: false)}',
        if (account.openAdvances > 0)
          'Advances ${kes(account.openAdvances, cents: false)}',
      ].join(' · ');
    }
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () => context.push('/members/$memberId/account'),
        leading: const Icon(
          Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        title: const Text(
          'Account',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          line,
          style: TextStyle(
            color: (account?.balance ?? 0) < 0 ? AppColors.error : null,
          ),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/network/dio_client.dart';
import '../data/payout_models.dart';
import '../data/payout_service.dart';

final payoutServiceProvider = Provider<PayoutService>(
  (ref) => PayoutService(ref.watch(dioClientProvider)),
);

final payRunsProvider = FutureProvider.autoDispose<PayRunList>(
  (ref) => ref.watch(payoutServiceProvider).payRuns(),
);

final payRunProvider = FutureProvider.autoDispose.family<PayRunDetail, String>(
  (ref, id) => ref.watch(payoutServiceProvider).payRun(id),
);

final deductionTypesProvider = FutureProvider.autoDispose<List<DeductionType>>(
  (ref) => ref.watch(payoutServiceProvider).deductionTypes(),
);

final farmerAccountProvider = FutureProvider.autoDispose
    .family<FarmerAccount, String>(
      (ref, memberId) => ref
          .watch(payoutServiceProvider)
          .account(
            memberId,
            from: DateTime(DateTime.now().year - 1, DateTime.now().month, 1),
          ),
    );

final farmerDeductionsProvider = FutureProvider.autoDispose
    .family<List<FarmerDeduction>, String>(
      (ref, memberId) =>
          ref.watch(payoutServiceProvider).farmerDeductions(memberId),
    );

/// A pay run's period as people say it: "September 2026" for a whole month,
/// otherwise "1 Oct – 15 Oct 2026".
String periodLabel(DateTime from, DateTime to) {
  final wholeMonth =
      from.day == 1 &&
      to.add(const Duration(days: 1)).day == 1 &&
      from.month == to.month &&
      from.year == to.year;
  if (wholeMonth) return DateFormat('MMMM y').format(from);
  return '${DateFormat('d MMM').format(from)} – ${DateFormat('d MMM y').format(to)}';
}

String shortDate(DateTime d) => DateFormat('d MMM y').format(d);

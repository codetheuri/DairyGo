import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import 'member_price.dart';

final memberPriceServiceProvider = Provider<MemberPriceService>(
  (ref) => MemberPriceService(ref.watch(dioClientProvider)),
);

final memberPricesProvider = FutureProvider.autoDispose
    .family<MemberPrices, String>(
      (ref, memberId) => ref.watch(memberPriceServiceProvider).prices(memberId),
    );

/// The price a farmer's milk is bought at today, for the intake form.
final memberPriceTodayProvider = FutureProvider.autoDispose
    .family<({double price, bool own}), String>(
      (ref, memberId) =>
          ref.watch(memberPriceServiceProvider).priceToday(memberId),
    );

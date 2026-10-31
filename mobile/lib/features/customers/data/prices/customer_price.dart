import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_call.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/money.dart';

/// One row of a customer's price history.
class CustomerPriceRow {
  final String id;
  final double price;
  final DateTime from;
  final String? reason;
  final String? setBy;
  final String? voidReason;

  const CustomerPriceRow({
    required this.id,
    required this.price,
    required this.from,
    this.reason,
    this.setBy,
    this.voidReason,
  });

  factory CustomerPriceRow.fromJson(Map<String, dynamic> j) => CustomerPriceRow(
    id: j['id'] as String,
    price: toDouble(j['price_per_litre']),
    from: DateTime.tryParse('${j['effective_date']}') ?? DateTime(2000),
    reason: j['reason'] as String?,
    setBy: j['created_by'] as String?,
    voidReason: j['void_reason'] as String?,
  );
}

/// A customer's price today, the earliest day a price may start, and their
/// price history (newest first).
class CustomerPrices {
  final double? today;
  final DateTime firstDay;
  final List<CustomerPriceRow> schedule;
  final List<CustomerPriceRow> cancelled;

  const CustomerPrices({
    required this.today,
    required this.firstDay,
    required this.schedule,
    required this.cancelled,
  });

  factory CustomerPrices.fromJson(Map<String, dynamic> j) => CustomerPrices(
    today: j['price_today'] == null ? null : toDouble(j['price_today']),
    firstDay: DateTime.tryParse('${j['first_day']}') ?? DateTime(2000),
    schedule: [
      for (final r in (j['schedule'] as List?) ?? const [])
        CustomerPriceRow.fromJson(r as Map<String, dynamic>),
    ],
    cancelled: [
      for (final r in (j['cancelled'] as List?) ?? const [])
        CustomerPriceRow.fromJson(r as Map<String, dynamic>),
    ],
  );
}

/// What a price change does: sales not fully paid are always repriced;
/// sales paid in full only when chosen.
class RepriceSummary {
  final int creditSales;
  final double creditChange;
  final int paidSales;
  final double paidChange;
  final int handtyped;
  final int repriced;

  const RepriceSummary({
    required this.creditSales,
    required this.creditChange,
    required this.paidSales,
    required this.paidChange,
    required this.handtyped,
    required this.repriced,
  });

  factory RepriceSummary.fromJson(Map<String, dynamic> j) {
    final s = (j['summary'] as Map<String, dynamic>?) ?? const {};
    return RepriceSummary(
      creditSales: (s['credit_sales'] as num?)?.toInt() ?? 0,
      creditChange: toDouble(s['credit_change']),
      paidSales: (s['paid_sales'] as num?)?.toInt() ?? 0,
      paidChange: toDouble(s['paid_change']),
      handtyped: (s['handtyped_sales'] as num?)?.toInt() ?? 0,
      repriced: (j['repriced'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The customer price API (backend internal/collection/customer_price.go).
class CustomerPriceService {
  final Dio _dio;

  CustomerPriceService(this._dio);

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<CustomerPrices> prices(String customerId) async =>
      CustomerPrices.fromJson(
        await apiData(
          () => _dio.get('/api/v1/sacco/customers/$customerId/prices'),
          "Could not load the customer's price",
        ),
      );

  /// Saves (or with [preview], only reports) a price from [from].
  Future<RepriceSummary> setPrice(
    String customerId, {
    required double price,
    required DateTime from,
    required String reason,
    required bool includePaid,
    bool preview = false,
  }) async => RepriceSummary.fromJson(
    await apiData(
      () => _dio.post(
        '/api/v1/sacco/customers/$customerId/prices',
        data: {
          'price_per_litre': price,
          'effective_date': iso(from),
          'reason': reason,
          if (includePaid) 'include_paid': true,
          if (preview) 'preview': true,
        },
      ),
      'The price could not be saved',
    ),
  );

  /// Cancels a price entered in error (or with [preview], only reports).
  Future<RepriceSummary> cancel(
    String customerId,
    String priceId, {
    required String reason,
    required bool includePaid,
    bool preview = false,
  }) async => RepriceSummary.fromJson(
    await apiData(
      () => _dio.post(
        '/api/v1/sacco/customers/$customerId/prices/$priceId/void',
        data: {
          'reason': reason,
          if (includePaid) 'include_paid': true,
          if (preview) 'preview': true,
        },
      ),
      'The price could not be cancelled',
    ),
  );
}

final customerPriceServiceProvider = Provider<CustomerPriceService>(
  (ref) => CustomerPriceService(ref.watch(dioClientProvider)),
);

final customerPricesProvider = FutureProvider.autoDispose
    .family<CustomerPrices, String>(
      (ref, id) => ref.watch(customerPriceServiceProvider).prices(id),
    );

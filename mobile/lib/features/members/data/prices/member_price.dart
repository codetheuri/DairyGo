import 'package:dio/dio.dart';

import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';

/// One row of a farmer's own price schedule; [price] null means "back to
/// the Sacco's price" from [from].
class MemberPriceRow {
  final String id;
  final double? price;
  final DateTime from;
  final String? reason;

  const MemberPriceRow({
    required this.id,
    required this.price,
    required this.from,
    this.reason,
  });

  factory MemberPriceRow.fromJson(Map<String, dynamic> j) => MemberPriceRow(
    id: j['id'] as String,
    price: j['price_per_litre'] == null ? null : toDouble(j['price_per_litre']),
    from: DateTime.tryParse('${j['effective_date']}') ?? DateTime(2000),
    reason: j['reason'] as String?,
  );
}

/// A farmer's buying price today and their own schedule.
class MemberPrices {
  final double today;
  final bool own;
  final double saccoToday;
  final List<MemberPriceRow> schedule;

  const MemberPrices({
    required this.today,
    required this.own,
    required this.saccoToday,
    required this.schedule,
  });

  factory MemberPrices.fromJson(Map<String, dynamic> j) => MemberPrices(
    today: toDouble(j['price_today']),
    own: j['own_price'] as bool? ?? false,
    saccoToday: toDouble(j['sacco_price_today']),
    schedule: [
      for (final r in (j['schedule'] as List?) ?? const [])
        MemberPriceRow.fromJson(r as Map<String, dynamic>),
    ],
  );
}

/// The farmer price API (backend internal/collection/member_price.go).
class MemberPriceService {
  final Dio _dio;

  MemberPriceService(this._dio);

  static String iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<MemberPrices> prices(String memberId) async => MemberPrices.fromJson(
    await apiData(
      () => _dio.get('/api/v1/sacco/members/$memberId/prices'),
      "Could not load the farmer's price",
    ),
  );

  /// The price their milk is bought at today, and whether it is their own.
  Future<({double price, bool own})> priceToday(String memberId) async {
    final data = await apiData(
      () => _dio.get('/api/v1/sacco/members/$memberId/price'),
      'Could not load the price',
    );
    return (
      price: toDouble(data['price_per_litre']),
      own: data['own_price'] as bool? ?? false,
    );
  }

  /// Saves (or with [preview], only counts) a price from [from]; [price]
  /// null puts the farmer back on the Sacco's price. Returns how many unpaid
  /// milk records change.
  Future<int> setPrice(
    String memberId, {
    required double? price,
    required DateTime from,
    required String reason,
    bool preview = false,
  }) async {
    final data = await apiData(
      () => _dio.post(
        '/api/v1/sacco/members/$memberId/prices',
        data: {
          if (price == null) 'back_to_sacco_price': true,
          'price_per_litre': ?price,
          'effective_date': iso(from),
          'reason': reason,
          if (preview) 'preview': true,
        },
      ),
      'The price could not be saved',
    );
    return (data['repriced'] as num?)?.toInt() ?? 0;
  }

  Future<int> cancel(String memberId, String priceId, String reason) async {
    final data = await apiData(
      () => _dio.post(
        '/api/v1/sacco/members/$memberId/prices/$priceId/void',
        data: {'reason': reason},
      ),
      'The price could not be cancelled',
    );
    return (data['repriced'] as num?)?.toInt() ?? 0;
  }
}

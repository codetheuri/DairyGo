// Demo data for the guide pictures: believable farmers, customers and a
// collector's day, so staff recognise what they see. Starts from the
// collector fixtures (test/layout/fixtures/collector) and replaces the rows.
// Nothing here is real Sacco data.

import 'dart:convert';
import 'dart:io';

import 'package:dairy_sacco_mobile/features/auth/domain/entities/user_entity.dart';

typedef Person = ({String id, String name});

/// Read from the collector fixture so the shapes stay the app's own.
Map<String, dynamic> _fixture(String name) =>
    (jsonDecode(
              File(
                'test/layout/fixtures/collector/$name.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>)['body']
        as Map<String, dynamic>;

Map<String, Object> _ok(Map<String, Object?> data) => {
  'success': true,
  'message': 'ok',
  'data': data,
};

const _today = '2026-10-05';

final guideFarmer = (
  id: 'b1a3c2d4-0001-4f00-9a00-000000000001',
  name: 'Jane Wanjiru Muthoni',
);

const _farmers = [
  (
    'b1a3c2d4-0001-4f00-9a00-000000000001',
    'MEM-0101',
    'Jane Wanjiru',
    'Muthoni',
    '0712 345 101',
  ),
  (
    'b1a3c2d4-0002-4f00-9a00-000000000002',
    'MEM-0102',
    'Peter',
    'Kamau',
    '0712 345 102',
  ),
  (
    'b1a3c2d4-0003-4f00-9a00-000000000003',
    'MEM-0103',
    'Mary',
    'Achieng',
    '0712 345 103',
  ),
  (
    'b1a3c2d4-0004-4f00-9a00-000000000004',
    'MEM-0104',
    'John',
    'Kiprotich',
    '0712 345 104',
  ),
  (
    'b1a3c2d4-0005-4f00-9a00-000000000005',
    'MEM-0105',
    'Grace',
    'Njeri',
    '0712 345 105',
  ),
];

/// Customers, biggest debt first, as the owing list shows them.
final guideCustomers =
    <({String id, String name, String type, double price, double owes})>[
      (
        id: 'c0570e00-0001-4c00-8a00-000000000001',
        name: 'Kiambu Cooler',
        type: 'COOLER',
        price: 62,
        owes: 18600,
      ),
      (
        id: 'c0570e00-0002-4c00-8a00-000000000002',
        name: 'Mama Njeri Hotel',
        type: 'HOTEL',
        price: 70,
        owes: 2800,
      ),
      (
        id: 'c0570e00-0003-4c00-8a00-000000000003',
        name: 'Ruiru Milk Bar',
        type: 'SHOP',
        price: 68,
        owes: 0,
      ),
    ];

final guideCollectors = <({int id, String name})>[
  (id: 31, name: 'Grace Wambui'),
  (id: 32, name: 'Peter Njoroge'),
];

/// What a collector at Maru may do, including customer balances and
/// recording customers' payments.
List<String> get collectorPermissions => [
  ...(_fixture('auth_me')['data']['user']['permissions'] as List)
      .cast<String>(),
  'customers.statement.read',
  'customers.payments.manage',
];

/// The collector the pictures are taken as.
UserEntity guideCollector() {
  final user = Map<String, dynamic>.from(
    _fixture('auth_me')['data']['user'] as Map,
  );
  user['profile'] = <String, dynamic>{
    ...(user['profile'] as Map).cast<String, dynamic>(),
    'first_name': 'Alice',
    'last_name': 'Wanjiru',
  };
  return UserEntity.fromJson(user);
}

Map<String, Object?> _customer(int i) {
  final c = guideCustomers[i];
  return {
    'id': c.id,
    'sacco_id': 'demo',
    'name': c.name,
    'phone': '0733 000 00${i + 1}',
    'customer_type': c.type,
    'default_price_per_litre': c.price,
    'status': 'ACTIVE',
    'created_at': '2026-09-01T08:00:00+03:00',
    'updated_at': '2026-09-01T08:00:00+03:00',
    'balance': c.owes,
  };
}

/// Answers by fixture name (see FixtureAdapter.replaced).
Map<String, Object> guideAnswers() {
  final members = _fixture('sacco_members')['data'] as Map<String, dynamic>;
  final template = (members['members'] as List).first as Map<String, dynamic>;
  final first = guideCustomers.first;
  return {
    'sacco_dashboard_collector': _ok({
      ...(_fixture('sacco_dashboard_collector')['data']
          as Map<String, dynamic>),
      'collector_name': 'Alice Wanjiru',
      'date': _today,
      'today_collected_litres': 412.5,
      'today_purchases_amount': 20625,
      'today_farmers_serviced': 31,
      'today_sold_litres': 380,
      'today_sales_revenue': 24700,
      'today_cash_received': 9800,
      'today_spoiled_litres': 2,
      'today_received_litres': 0,
      'today_transferred_out_litres': 15,
      'today_unaccounted_litres': 15.5,
      'today_balance_status': 'MISSING',
    }),
    'sacco_members': _ok({
      'members': [
        for (final f in _farmers)
          {
            ...template,
            'id': f.$1,
            'membership_number': f.$2,
            'first_name': f.$3,
            'last_name': f.$4,
            'phone': f.$5,
            'location': 'Gatundu route',
          },
      ],
      'meta': {
        'page': 1,
        'per_page': 30,
        'total': _farmers.length,
        'total_pages': 1,
        'has_next': false,
        'has_previous': false,
      },
    }),
    'sacco_customers': _ok({
      'customers': [
        for (var i = 0; i < guideCustomers.length; i++) _customer(i),
      ],
      'meta': {
        'page': 1,
        'per_page': 30,
        'total': guideCustomers.length,
        'total_pages': 1,
        'has_next': false,
        'has_previous': false,
      },
    }),
    'sacco_customers_balances': _ok({
      'balances': [
        for (final c in guideCustomers.where((c) => c.owes > 0))
          {
            'customer_id': c.id,
            'name': c.name,
            'phone': '0733 000 001',
            'customer_type': c.type,
            'total_sales': c.owes + 12000,
            'total_paid': 12000,
            'balance': c.owes,
          },
      ],
      'total_owed': guideCustomers.fold<double>(0, (t, c) => t + c.owes),
    }),
    'sacco_customers_${first.id}': _ok({'customer': _customer(0)}),
    'sacco_customers_${first.id}_statement': _ok({
      'statement': {
        'customer': _customer(0),
        'from_date': '2026-10-01',
        'to_date': _today,
        'opening_balance': 12400,
        'total_debit': 18600,
        'total_credit': 12400,
        'closing_balance': first.owes,
        'lines': [
          {
            'kind': 'SALE',
            'reference_id': 's1',
            'date': '2026-10-01',
            'description': 'Milk sale',
            'litres': 100,
            'debit': 6200,
            'credit': 0,
            'balance': 18600,
          },
          {
            'kind': 'PAYMENT',
            'reference_id': 'p1',
            'date': '2026-10-02',
            'description': 'M-Pesa payment',
            'litres': 0,
            'debit': 0,
            'credit': 12400,
            'balance': 6200,
          },
          {
            'kind': 'SALE',
            'reference_id': 's2',
            'date': '2026-10-03',
            'description': 'Milk sale',
            'litres': 100,
            'debit': 6200,
            'credit': 0,
            'balance': 12400,
          },
          {
            'kind': 'SALE',
            'reference_id': 's3',
            'date': '2026-10-04',
            'description': 'Milk sale',
            'litres': 100,
            'debit': 6200,
            'credit': 0,
            'balance': 18600,
          },
        ],
      },
    }),
    'sacco_reconciliation': _ok({
      'reconciliation': {
        ...((_fixture('sacco_reconciliation')['data']
                as Map<String, dynamic>)['reconciliation']
            as Map<String, dynamic>),
        'collector_name': 'Alice Wanjiru',
        'date': _today,
        'total_collected_litres': 412.5,
        'total_sold_litres': 380,
        'total_spoiled_litres': 2,
        'unaccounted_litres': 15.5,
        'total_sales_amount': 24700,
        'cash_received_amount': 9800,
        'credit_sales_amount': 14900,
        'total_purchases_amount': 20625,
        'total_received_litres': 0,
        'total_transferred_out_litres': 15,
        'transfers': <Object>[],
      },
    }),
    'sacco_milk-transfers_recipients': _ok({
      'collectors': [
        for (final c in guideCollectors)
          {
            'id': c.id,
            'name': c.name,
            'username': c.name.split(' ').first.toLowerCase(),
          },
      ],
    }),
  };
}

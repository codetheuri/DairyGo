// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CustomerModelImpl _$$CustomerModelImplFromJson(Map<String, dynamic> json) =>
    _$CustomerModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      customerType: json['customer_type'] as String? ?? 'OTHER',
      defaultPricePerLitre: (json['default_price_per_litre'] as num?)
          ?.toDouble(),
      status: json['status'] as String? ?? 'ACTIVE',
      notes: json['notes'] as String?,
      balance: (json['balance'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$CustomerModelImplToJson(_$CustomerModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'customer_type': instance.customerType,
      'default_price_per_litre': instance.defaultPricePerLitre,
      'status': instance.status,
      'notes': instance.notes,
      'balance': instance.balance,
    };

_$CreateCustomerRequestModelImpl _$$CreateCustomerRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$CreateCustomerRequestModelImpl(
  name: json['name'] as String,
  phone: json['phone'] as String?,
  customerType: json['customer_type'] as String? ?? 'OTHER',
  defaultPricePerLitre: (json['default_price_per_litre'] as num?)?.toDouble(),
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$CreateCustomerRequestModelImplToJson(
  _$CreateCustomerRequestModelImpl instance,
) => <String, dynamic>{
  'name': instance.name,
  'phone': instance.phone,
  'customer_type': instance.customerType,
  'default_price_per_litre': instance.defaultPricePerLitre,
  'notes': instance.notes,
};

_$StatementLineModelImpl _$$StatementLineModelImplFromJson(
  Map<String, dynamic> json,
) => _$StatementLineModelImpl(
  kind: json['kind'] as String? ?? 'SALE',
  referenceId: json['reference_id'] as String? ?? '',
  date: json['date'] as String? ?? '',
  description: json['description'] as String? ?? '',
  litres: (json['litres'] as num?)?.toDouble() ?? 0.0,
  debit: (json['debit'] as num?)?.toDouble() ?? 0.0,
  credit: (json['credit'] as num?)?.toDouble() ?? 0.0,
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$StatementLineModelImplToJson(
  _$StatementLineModelImpl instance,
) => <String, dynamic>{
  'kind': instance.kind,
  'reference_id': instance.referenceId,
  'date': instance.date,
  'description': instance.description,
  'litres': instance.litres,
  'debit': instance.debit,
  'credit': instance.credit,
  'balance': instance.balance,
};

_$CustomerStatementModelImpl _$$CustomerStatementModelImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerStatementModelImpl(
  customer: CustomerModel.fromJson(json['customer'] as Map<String, dynamic>),
  fromDate: json['from_date'] as String? ?? '',
  toDate: json['to_date'] as String? ?? '',
  openingBalance: (json['opening_balance'] as num?)?.toDouble() ?? 0.0,
  totalDebit: (json['total_debit'] as num?)?.toDouble() ?? 0.0,
  totalCredit: (json['total_credit'] as num?)?.toDouble() ?? 0.0,
  closingBalance: (json['closing_balance'] as num?)?.toDouble() ?? 0.0,
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => StatementLineModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$$CustomerStatementModelImplToJson(
  _$CustomerStatementModelImpl instance,
) => <String, dynamic>{
  'customer': instance.customer,
  'from_date': instance.fromDate,
  'to_date': instance.toDate,
  'opening_balance': instance.openingBalance,
  'total_debit': instance.totalDebit,
  'total_credit': instance.totalCredit,
  'closing_balance': instance.closingBalance,
  'lines': instance.lines,
};

_$CustomerBalanceModelImpl _$$CustomerBalanceModelImplFromJson(
  Map<String, dynamic> json,
) => _$CustomerBalanceModelImpl(
  customerId: json['customer_id'] as String,
  name: json['name'] as String,
  phone: json['phone'] as String?,
  customerType: json['customer_type'] as String? ?? 'OTHER',
  totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
  totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
  balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$CustomerBalanceModelImplToJson(
  _$CustomerBalanceModelImpl instance,
) => <String, dynamic>{
  'customer_id': instance.customerId,
  'name': instance.name,
  'phone': instance.phone,
  'customer_type': instance.customerType,
  'total_sales': instance.totalSales,
  'total_paid': instance.totalPaid,
  'balance': instance.balance,
};

_$RecordPaymentRequestModelImpl _$$RecordPaymentRequestModelImplFromJson(
  Map<String, dynamic> json,
) => _$RecordPaymentRequestModelImpl(
  amount: (json['amount'] as num).toDouble(),
  paymentDate: json['payment_date'] as String?,
  method: json['method'] as String? ?? 'CASH',
  reference: json['reference'] as String?,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$$RecordPaymentRequestModelImplToJson(
  _$RecordPaymentRequestModelImpl instance,
) => <String, dynamic>{
  'amount': instance.amount,
  'payment_date': instance.paymentDate,
  'method': instance.method,
  'reference': instance.reference,
  'notes': instance.notes,
};

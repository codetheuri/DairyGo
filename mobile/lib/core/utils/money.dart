/// Money and numbers as people read them: KES 13,487.00, 1,234.5 L.
String kes(num amount, {bool cents = true}) {
  final negative = amount < 0;
  final text = thousands(amount.abs(), decimals: cents ? 2 : 0);
  return negative ? '-KES $text' : 'KES $text';
}

/// [value] with comma thousand separators and [decimals] places.
String thousands(num value, {int decimals = 2}) {
  final fixed = value.toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final whole = parts[0].replaceFirst('-', '');
  final out = StringBuffer(value < 0 && double.parse(fixed) != 0 ? '-' : '');
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) out.write(',');
    out.write(whole[i]);
  }
  if (parts.length > 1) out.write('.${parts[1]}');
  return out.toString();
}

/// Litres without needless zeros: 412.5 L, 400 L.
String litres(num value) {
  var s = value.toStringAsFixed(2);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$s L';
}

double toDouble(Object? v) => switch (v) {
  num n => n.toDouble(),
  String s => double.tryParse(s) ?? 0,
  _ => 0,
};

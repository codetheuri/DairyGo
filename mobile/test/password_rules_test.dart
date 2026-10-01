import 'package:dairy_sacco_mobile/core/constants/password_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same password rule as the API and the console', () {
    expect(minPasswordLength, 4);
    expect(checkNewPassword(null), isNotNull);
    expect(checkNewPassword('abc'), 'Password must be at least 4 characters');
    expect(checkNewPassword('abcd'), isNull);
    expect(checkNewPassword('1234'), isNull); // a PIN is fine
  });
}

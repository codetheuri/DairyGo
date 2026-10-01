/// Who made and supports the app. Shown on the splash and sign-in screens
/// and in "About DairyGo" on the More page; change it here only.
abstract final class Developer {
  static const name = 'Joseph Theuri';
  static const role = 'Developer, DairyGo';
  static const phone = '0706 063 617';
  static const email = 'theurij113@gmail.com';

  /// For tel: links (no spaces).
  static String get dialPhone => phone.replaceAll(' ', '');
}

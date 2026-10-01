import 'package:flutter/widgets.dart' show StringCharacters;

/// Shortest password accepted anywhere: the same rule as the API and the
/// platform console (auth.MinPasswordLength on the server).
const minPasswordLength = 4;

/// The form check for a new password: null when it is long enough.
String? checkNewPassword(String? value) =>
    value == null || value.characters.length < minPasswordLength
    ? 'Password must be at least $minPasswordLength characters'
    : null;

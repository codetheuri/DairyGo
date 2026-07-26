/// Failure represents domain-level error representations in Clean Architecture.
/// 
/// Senior Architect Note:
/// UI widgets should NEVER catch raw DioException or HTTP status codes directly.
/// The Data Layer maps HTTP/Dio errors into structured Failure objects,
/// ensuring presentation widgets present clear user messages.
abstract class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {super.code});
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No Internet connection. Please check your network setting and try again.']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired. Please log in again.']);
}

class ValidationFailure extends Failure {
  final Map<String, String>? fieldErrors;

  const ValidationFailure(super.message, {this.fieldErrors, super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unexpected error occurred. Please try again later.']);
}

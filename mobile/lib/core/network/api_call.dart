import 'dart:convert';

import 'package:dio/dio.dart';

/// Runs a request and returns the envelope's `data`. A refusal becomes an
/// [Exception] carrying the server's reason, worded for the user.
Future<Map<String, dynamic>> apiData(
  Future<Response<dynamic>> Function() request,
  String fallback,
) async {
  try {
    final res = await request();
    final body = res.data;
    if (body is Map && body['success'] == true) {
      final data = body['data'];
      return data is Map<String, dynamic> ? data : const {};
    }
    throw Exception(body is Map ? body['message'] ?? fallback : fallback);
  } on DioException catch (e) {
    throw Exception(serverMessage(e) ?? fallback);
  }
}

/// The server's reason for refusing: a single sentence the API puts in
/// `errors.server`, else the first field error, else the message. Bodies
/// downloaded as bytes are decoded first.
String? serverMessage(DioException e) {
  var data = e.response?.data;
  if (data is List<int>) {
    try {
      data = jsonDecode(utf8.decode(data));
    } catch (_) {
      return null;
    }
  }
  if (data is! Map) {
    return e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.connectionTimeout
        ? 'No connection. Check your internet and try again.'
        : null;
  }
  final errors = data['errors'];
  if (errors is Map && errors.isNotEmpty) {
    final first = (errors['server'] ?? errors.values.first)?.toString();
    if (first != null && first.isNotEmpty) return first;
  }
  final msg = data['message']?.toString();
  return (msg == null || msg.isEmpty) ? null : msg;
}

/// [e] as a sentence for the screen.
String errorText(Object e) => e.toString().replaceFirst('Exception: ', '');

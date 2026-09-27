import 'package:freezed_annotation/freezed_annotation.dart';

part 'audit_log_model.freezed.dart';
part 'audit_log_model.g.dart';

/// One entry in a record's audit history (who changed what, when and why).
/// Returned by the `/history` endpoints of collections, sales and customers.
/// [oldValues] and [newValues] are JSON snapshots of the record's fields.
@freezed
class AuditLogModel with _$AuditLogModel {
  const factory AuditLogModel({
    required String id,
    @Default('') String action,
    @JsonKey(name: 'actor_name') String? actorName,
    String? reason,
    @JsonKey(name: 'old_values') String? oldValues,
    @JsonKey(name: 'new_values') String? newValues,
    @JsonKey(name: 'created_at') String? createdAt,
  }) = _AuditLogModel;

  factory AuditLogModel.fromJson(Map<String, dynamic> json) => _$AuditLogModelFromJson(json);
}

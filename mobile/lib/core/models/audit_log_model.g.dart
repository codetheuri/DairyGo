// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AuditLogModelImpl _$$AuditLogModelImplFromJson(Map<String, dynamic> json) =>
    _$AuditLogModelImpl(
      id: json['id'] as String,
      action: json['action'] as String? ?? '',
      actorName: json['actor_name'] as String?,
      reason: json['reason'] as String?,
      oldValues: json['old_values'] as String?,
      newValues: json['new_values'] as String?,
      createdAt: json['created_at'] as String?,
    );

Map<String, dynamic> _$$AuditLogModelImplToJson(_$AuditLogModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'action': instance.action,
      'actor_name': instance.actorName,
      'reason': instance.reason,
      'old_values': instance.oldValues,
      'new_values': instance.newValues,
      'created_at': instance.createdAt,
    };

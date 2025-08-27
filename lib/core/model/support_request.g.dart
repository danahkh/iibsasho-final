// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SupportRequestImpl _$$SupportRequestImplFromJson(Map<String, dynamic> json) =>
    _$SupportRequestImpl(
      id: json['id'] as String?,
      userId: json['user_id'] as String?,
      userEmail: json['user_email'] as String?,
      category: json['category'] as String?,
      reason: json['reason'] as String?,
      title: json['title'] as String?,
      message: json['message'] as String?,
      details: json['details'] as String?,
      status: json['status'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
    );

Map<String, dynamic> _$$SupportRequestImplToJson(
  _$SupportRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'user_email': instance.userEmail,
  'category': instance.category,
  'reason': instance.reason,
  'title': instance.title,
  'message': instance.message,
  'details': instance.details,
  'status': instance.status,
  'created_at': instance.createdAt?.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'resolved_at': instance.resolvedAt?.toIso8601String(),
  'resolved_by': instance.resolvedBy,
};

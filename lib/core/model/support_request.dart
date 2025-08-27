// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_request.freezed.dart';
part 'support_request.g.dart';

@freezed
class SupportRequest with _$SupportRequest {
  const factory SupportRequest({
    String? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_email') String? userEmail,
    String? category,
    String? reason,
    String? title,
    String? message,
    String? details,
    String? status, // 'open' | 'resolved'
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  }) = _SupportRequest;

  factory SupportRequest.fromJson(Map<String, dynamic> json) => _$SupportRequestFromJson(json);
}

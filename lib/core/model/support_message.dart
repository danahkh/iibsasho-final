// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_message.freezed.dart';
part 'support_message.g.dart';

@freezed
class SupportMessage with _$SupportMessage {
  const factory SupportMessage({
    String? id,
    @JsonKey(name: 'support_request_id') String? supportRequestId,
    String? message,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_role') String? senderRole, // 'admin' | 'user'
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _SupportMessage;

  factory SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);
}

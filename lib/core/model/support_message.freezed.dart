// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SupportMessage _$SupportMessageFromJson(Map<String, dynamic> json) {
  return _SupportMessage.fromJson(json);
}

/// @nodoc
mixin _$SupportMessage {
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'support_request_id')
  String? get supportRequestId => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  @JsonKey(name: 'sender_id')
  String? get senderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'sender_role')
  String? get senderRole => throw _privateConstructorUsedError; // 'admin' | 'user'
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this SupportMessage to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SupportMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SupportMessageCopyWith<SupportMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupportMessageCopyWith<$Res> {
  factory $SupportMessageCopyWith(
    SupportMessage value,
    $Res Function(SupportMessage) then,
  ) = _$SupportMessageCopyWithImpl<$Res, SupportMessage>;
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'support_request_id') String? supportRequestId,
    String? message,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_role') String? senderRole,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$SupportMessageCopyWithImpl<$Res, $Val extends SupportMessage>
    implements $SupportMessageCopyWith<$Res> {
  _$SupportMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SupportMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? supportRequestId = freezed,
    Object? message = freezed,
    Object? senderId = freezed,
    Object? senderRole = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            supportRequestId: freezed == supportRequestId
                ? _value.supportRequestId
                : supportRequestId // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            senderId: freezed == senderId
                ? _value.senderId
                : senderId // ignore: cast_nullable_to_non_nullable
                      as String?,
            senderRole: freezed == senderRole
                ? _value.senderRole
                : senderRole // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SupportMessageImplCopyWith<$Res>
    implements $SupportMessageCopyWith<$Res> {
  factory _$$SupportMessageImplCopyWith(
    _$SupportMessageImpl value,
    $Res Function(_$SupportMessageImpl) then,
  ) = __$$SupportMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'support_request_id') String? supportRequestId,
    String? message,
    @JsonKey(name: 'sender_id') String? senderId,
    @JsonKey(name: 'sender_role') String? senderRole,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$SupportMessageImplCopyWithImpl<$Res>
    extends _$SupportMessageCopyWithImpl<$Res, _$SupportMessageImpl>
    implements _$$SupportMessageImplCopyWith<$Res> {
  __$$SupportMessageImplCopyWithImpl(
    _$SupportMessageImpl _value,
    $Res Function(_$SupportMessageImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SupportMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? supportRequestId = freezed,
    Object? message = freezed,
    Object? senderId = freezed,
    Object? senderRole = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$SupportMessageImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        supportRequestId: freezed == supportRequestId
            ? _value.supportRequestId
            : supportRequestId // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        senderId: freezed == senderId
            ? _value.senderId
            : senderId // ignore: cast_nullable_to_non_nullable
                  as String?,
        senderRole: freezed == senderRole
            ? _value.senderRole
            : senderRole // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SupportMessageImpl implements _SupportMessage {
  const _$SupportMessageImpl({
    this.id,
    @JsonKey(name: 'support_request_id') this.supportRequestId,
    this.message,
    @JsonKey(name: 'sender_id') this.senderId,
    @JsonKey(name: 'sender_role') this.senderRole,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$SupportMessageImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupportMessageImplFromJson(json);

  @override
  final String? id;
  @override
  @JsonKey(name: 'support_request_id')
  final String? supportRequestId;
  @override
  final String? message;
  @override
  @JsonKey(name: 'sender_id')
  final String? senderId;
  @override
  @JsonKey(name: 'sender_role')
  final String? senderRole;
  // 'admin' | 'user'
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'SupportMessage(id: $id, supportRequestId: $supportRequestId, message: $message, senderId: $senderId, senderRole: $senderRole, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupportMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.supportRequestId, supportRequestId) ||
                other.supportRequestId == supportRequestId) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderRole, senderRole) ||
                other.senderRole == senderRole) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    supportRequestId,
    message,
    senderId,
    senderRole,
    createdAt,
  );

  /// Create a copy of SupportMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SupportMessageImplCopyWith<_$SupportMessageImpl> get copyWith =>
      __$$SupportMessageImplCopyWithImpl<_$SupportMessageImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SupportMessageImplToJson(this);
  }
}

abstract class _SupportMessage implements SupportMessage {
  const factory _SupportMessage({
    final String? id,
    @JsonKey(name: 'support_request_id') final String? supportRequestId,
    final String? message,
    @JsonKey(name: 'sender_id') final String? senderId,
    @JsonKey(name: 'sender_role') final String? senderRole,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$SupportMessageImpl;

  factory _SupportMessage.fromJson(Map<String, dynamic> json) =
      _$SupportMessageImpl.fromJson;

  @override
  String? get id;
  @override
  @JsonKey(name: 'support_request_id')
  String? get supportRequestId;
  @override
  String? get message;
  @override
  @JsonKey(name: 'sender_id')
  String? get senderId;
  @override
  @JsonKey(name: 'sender_role')
  String? get senderRole; // 'admin' | 'user'
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of SupportMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SupportMessageImplCopyWith<_$SupportMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

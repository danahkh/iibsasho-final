// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

SupportRequest _$SupportRequestFromJson(Map<String, dynamic> json) {
  return _SupportRequest.fromJson(json);
}

/// @nodoc
mixin _$SupportRequest {
  String? get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_email')
  String? get userEmail => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;
  String? get title => throw _privateConstructorUsedError;
  String? get message => throw _privateConstructorUsedError;
  String? get details => throw _privateConstructorUsedError;
  String? get status =>
      throw _privateConstructorUsedError; // 'open' | 'resolved'
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy => throw _privateConstructorUsedError;

  /// Serializes this SupportRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SupportRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SupportRequestCopyWith<SupportRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SupportRequestCopyWith<$Res> {
  factory $SupportRequestCopyWith(
    SupportRequest value,
    $Res Function(SupportRequest) then,
  ) = _$SupportRequestCopyWithImpl<$Res, SupportRequest>;
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_email') String? userEmail,
    String? category,
    String? reason,
    String? title,
    String? message,
    String? details,
    String? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class _$SupportRequestCopyWithImpl<$Res, $Val extends SupportRequest>
    implements $SupportRequestCopyWith<$Res> {
  _$SupportRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SupportRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? userEmail = freezed,
    Object? category = freezed,
    Object? reason = freezed,
    Object? title = freezed,
    Object? message = freezed,
    Object? details = freezed,
    Object? status = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: freezed == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String?,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String?,
            userEmail: freezed == userEmail
                ? _value.userEmail
                : userEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            category: freezed == category
                ? _value.category
                : category // ignore: cast_nullable_to_non_nullable
                      as String?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: freezed == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String?,
            message: freezed == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String?,
            details: freezed == details
                ? _value.details
                : details // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: freezed == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedAt: freezed == resolvedAt
                ? _value.resolvedAt
                : resolvedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            resolvedBy: freezed == resolvedBy
                ? _value.resolvedBy
                : resolvedBy // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SupportRequestImplCopyWith<$Res>
    implements $SupportRequestCopyWith<$Res> {
  factory _$$SupportRequestImplCopyWith(
    _$SupportRequestImpl value,
    $Res Function(_$SupportRequestImpl) then,
  ) = __$$SupportRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String? id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'user_email') String? userEmail,
    String? category,
    String? reason,
    String? title,
    String? message,
    String? details,
    String? status,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
    @JsonKey(name: 'resolved_at') DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') String? resolvedBy,
  });
}

/// @nodoc
class __$$SupportRequestImplCopyWithImpl<$Res>
    extends _$SupportRequestCopyWithImpl<$Res, _$SupportRequestImpl>
    implements _$$SupportRequestImplCopyWith<$Res> {
  __$$SupportRequestImplCopyWithImpl(
    _$SupportRequestImpl _value,
    $Res Function(_$SupportRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SupportRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? userId = freezed,
    Object? userEmail = freezed,
    Object? category = freezed,
    Object? reason = freezed,
    Object? title = freezed,
    Object? message = freezed,
    Object? details = freezed,
    Object? status = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
    Object? resolvedAt = freezed,
    Object? resolvedBy = freezed,
  }) {
    return _then(
      _$SupportRequestImpl(
        id: freezed == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String?,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String?,
        userEmail: freezed == userEmail
            ? _value.userEmail
            : userEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        category: freezed == category
            ? _value.category
            : category // ignore: cast_nullable_to_non_nullable
                  as String?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: freezed == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String?,
        message: freezed == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String?,
        details: freezed == details
            ? _value.details
            : details // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: freezed == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedAt: freezed == resolvedAt
            ? _value.resolvedAt
            : resolvedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        resolvedBy: freezed == resolvedBy
            ? _value.resolvedBy
            : resolvedBy // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SupportRequestImpl implements _SupportRequest {
  const _$SupportRequestImpl({
    this.id,
    @JsonKey(name: 'user_id') this.userId,
    @JsonKey(name: 'user_email') this.userEmail,
    this.category,
    this.reason,
    this.title,
    this.message,
    this.details,
    this.status,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
    @JsonKey(name: 'resolved_at') this.resolvedAt,
    @JsonKey(name: 'resolved_by') this.resolvedBy,
  });

  factory _$SupportRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SupportRequestImplFromJson(json);

  @override
  final String? id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  @JsonKey(name: 'user_email')
  final String? userEmail;
  @override
  final String? category;
  @override
  final String? reason;
  @override
  final String? title;
  @override
  final String? message;
  @override
  final String? details;
  @override
  final String? status;
  // 'open' | 'resolved'
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @override
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @override
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;

  @override
  String toString() {
    return 'SupportRequest(id: $id, userId: $userId, userEmail: $userEmail, category: $category, reason: $reason, title: $title, message: $message, details: $details, status: $status, createdAt: $createdAt, updatedAt: $updatedAt, resolvedAt: $resolvedAt, resolvedBy: $resolvedBy)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SupportRequestImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userEmail, userEmail) ||
                other.userEmail == userEmail) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.resolvedAt, resolvedAt) ||
                other.resolvedAt == resolvedAt) &&
            (identical(other.resolvedBy, resolvedBy) ||
                other.resolvedBy == resolvedBy));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    userId,
    userEmail,
    category,
    reason,
    title,
    message,
    details,
    status,
    createdAt,
    updatedAt,
    resolvedAt,
    resolvedBy,
  );

  /// Create a copy of SupportRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SupportRequestImplCopyWith<_$SupportRequestImpl> get copyWith =>
      __$$SupportRequestImplCopyWithImpl<_$SupportRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SupportRequestImplToJson(this);
  }
}

abstract class _SupportRequest implements SupportRequest {
  const factory _SupportRequest({
    final String? id,
    @JsonKey(name: 'user_id') final String? userId,
    @JsonKey(name: 'user_email') final String? userEmail,
    final String? category,
    final String? reason,
    final String? title,
    final String? message,
    final String? details,
    final String? status,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
    @JsonKey(name: 'resolved_at') final DateTime? resolvedAt,
    @JsonKey(name: 'resolved_by') final String? resolvedBy,
  }) = _$SupportRequestImpl;

  factory _SupportRequest.fromJson(Map<String, dynamic> json) =
      _$SupportRequestImpl.fromJson;

  @override
  String? get id;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  @JsonKey(name: 'user_email')
  String? get userEmail;
  @override
  String? get category;
  @override
  String? get reason;
  @override
  String? get title;
  @override
  String? get message;
  @override
  String? get details;
  @override
  String? get status; // 'open' | 'resolved'
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;
  @override
  @JsonKey(name: 'resolved_at')
  DateTime? get resolvedAt;
  @override
  @JsonKey(name: 'resolved_by')
  String? get resolvedBy;

  /// Create a copy of SupportRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SupportRequestImplCopyWith<_$SupportRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

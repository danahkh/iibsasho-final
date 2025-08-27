import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/notification_item.dart';
import '../utils/app_logger.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  // Get all notifications for current user
  static Stream<List<NotificationItem>> getUserNotifications() {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return Stream.value([]);

      return _supabase
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .map((data) => data.map((notification) => NotificationItem.fromMap(notification)).toList());
    } catch (e) {
      AppLogger.e('Error getting user notifications', e);
      return Stream.value([]);
    }
  }

  // Create a new notification
  static Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type, // 'comment', 'message', 'favorite'
    String? relatedId,
    String? relatedType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Prefer RPC to bypass any RLS edge cases
      final rpcResult = await _supabase.rpc('fn_create_notification', params: {
        'p_user_id': userId,
        'p_title': title,
        'p_message': message,
        'p_type': type,
        if (relatedId != null) 'p_related_id': relatedId,
        if (relatedType != null) 'p_related_type': relatedType,
        'p_metadata': metadata ?? {},
      });
      AppLogger.d('Notification RPC ok type=$type user=$userId id=$rpcResult relatedType=$relatedType');
      return true;
    } catch (e) {
      // Fallback to direct insert in case RPC is not deployed yet
      AppLogger.w('RPC fn_create_notification failed, falling back to insert: $e');
      try {
        final insertPayload = {
          'user_id': userId,
          'title': title,
          'message': message,
          'type': type,
          'related_id': relatedId,
          'related_type': relatedType,
          'is_read': false,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'metadata': metadata ?? {},
        };
        await _supabase.from('notifications').insert(insertPayload);
        AppLogger.d('Notification insert ok type=$type user=$userId relatedType=$relatedType');
        return true;
      } catch (e2) {
        AppLogger.e('Error creating notification (fallback failed)', e2);
        return false;
      }
    }
  }

  // Send notification when someone comments on a listing
  static Future<bool> sendCommentNotification({
    required String listingOwnerId,
    required String commenterName,
    required String listingTitle,
    required String listingId,
    required String commentId,
  }) async {
    return await createNotification(
      userId: listingOwnerId,
      title: 'New comment on your listing',
      message: '$commenterName commented on your listing',
      type: 'comment',
      relatedId: listingId,
      relatedType: 'listing',
      metadata: {
        'commenter_name': commenterName,
        'comment_id': commentId,
        'listing_title': listingTitle,
      },
    );
  }

  // Send notification when someone sends a message
  static Future<bool> sendMessageNotification({
    required String recipientId,
    required String senderName,
    required String chatId,
    required String listingTitle,
  }) async {
    return await createNotification(
      userId: recipientId,
      title: 'New message',
      message: '$senderName sent you a message',
      type: 'message',
      relatedId: chatId,
      relatedType: 'chat',
      metadata: {
        'sender_name': senderName,
        'listing_title': listingTitle,
      },
    );
  }

  // Send notification when someone favorites a listing
  static Future<bool> sendFavoriteNotification({
    required String listingOwnerId,
    required String favoriterName,
    required String listingTitle,
    required String listingId,
  }) async {
    return await createNotification(
      userId: listingOwnerId,
      title: 'Someone liked your listing',
      message: '$favoriterName added "$listingTitle" to their favorites',
      type: 'favorite',
      relatedId: listingId,
      relatedType: 'listing',
      metadata: {
        'favoriter_name': favoriterName,
        'listing_title': listingTitle,
      },
    );
  }

  // Send notification when someone replies to a comment
  static Future<bool> sendCommentReplyNotification({
    required String parentAuthorId,
    required String replierName,
    required String listingTitle,
    required String commentId,
    required String listingId,
  }) async {
    return await createNotification(
      userId: parentAuthorId,
      title: 'New reply to your comment',
      message: '$replierName replied to your comment on "$listingTitle"',
      type: 'comment',
      relatedId: commentId,
      relatedType: 'comment',
      metadata: {
        'replier_name': replierName,
        'listing_title': listingTitle,
        'listing_id': listingId,
      },
    );
  }

  // Send notification when someone likes a comment
  static Future<bool> sendCommentLikeNotification({
    required String commentAuthorId,
    required String likerName,
    required String listingTitle,
    required String commentId,
    required String listingId,
  }) async {
    return await createNotification(
      userId: commentAuthorId,
      title: 'Someone liked your comment',
      message: '$likerName liked your comment on "$listingTitle"',
      type: 'comment',
      relatedId: commentId,
      relatedType: 'comment',
      metadata: {
        'liker_name': likerName,
        'listing_title': listingTitle,
        'listing_id': listingId,
      },
    );
  }

  // Admin broadcast to many users (fan-out on client)
  static Future<int> sendAdminBroadcast({
    required String title,
    required String message,
    List<String>? targetUserIds,
    bool excludeCurrentUser = true,
  }) async {
    try {
      List<String> recipients = targetUserIds ?? [];
      if (recipients.isEmpty) {
        // Fetch all user ids from users table
        final rows = await _supabase.from('users').select('id');
        recipients = List<String>.from(rows.map((r) => r['id'].toString()));
      }
      final me = _supabase.auth.currentUser?.id;
      if (excludeCurrentUser && me != null) {
        recipients = recipients.where((id) => id != me).toList();
      }
      int ok = 0;
      for (final uid in recipients) {
        final success = await createNotification(
          userId: uid,
          title: title,
          message: message,
          // Use 'message' type to satisfy DB constraint
          type: 'message',
          relatedType: 'admin',
          metadata: {'scope': 'admin_broadcast'},
        );
        if (success) ok++;
      }
      return ok;
    } catch (e) {
      AppLogger.e('Admin broadcast failed', e);
      return 0;
    }
  }

  // Utility: send a quick self test notification to current user (for diagnostics)
  static Future<bool> sendSelfTest({
    String type = 'message',
    String title = 'Test notification',
    String message = 'This is a test',
  }) async {
    try {
      final me = _supabase.auth.currentUser?.id;
      if (me == null) {
        AppLogger.w('sendSelfTest: no current user');
        return false;
      }
      return await createNotification(
        userId: me,
        title: title,
        message: message,
        type: type,
        relatedType: 'admin',
        metadata: {'scope': 'self_test'},
      );
    } catch (e) {
      AppLogger.e('sendSelfTest failed', e);
      return false;
    }
  }

  // Mark notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      return true;
    } catch (e) {
      AppLogger.e('Error marking notification as read', e);
      return false;
    }
  }

  // Mark all notifications as read for a user
  static Future<bool> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } catch (e) {
      AppLogger.e('Error marking all notifications as read', e);
      return false;
    }
  }

  // Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId);
      return true;
    } catch (e) {
      AppLogger.e('Error deleting notification', e);
      return false;
    }
  }

  // Get unread count
  static Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('is_read', false);
      return response.length;
    } catch (e) {
      AppLogger.e('Error getting unread count', e);
      return 0;
    }
  }

  // Helper methods for common notifications - REMOVED
  // These are replaced by the new methods above:
  // - sendCommentNotification
  // - sendMessageNotification  
  // - sendFavoriteNotification
}

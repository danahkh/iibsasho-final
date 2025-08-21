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
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'related_type': relatedType,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      });
      return true;
    } catch (e) {
      AppLogger.e('Error creating notification', e);
      return false;
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
      message: '$commenterName commented on "$listingTitle"',
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
      message: '$senderName sent you a message about "$listingTitle"',
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

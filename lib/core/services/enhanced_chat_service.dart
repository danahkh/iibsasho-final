import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class ChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Create or get existing chat between two users about a listing
  static Future<String?> createOrGetChat({
    required String otherUserId,
    required String listingId,
    required String listingTitle,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Create a consistent chat ID based on participants and listing
      final participants = [user.id, otherUserId]..sort();
      final chatId = '${participants[0]}_${participants[1]}_$listingId';

      final chatResponse = await _supabase
          .from('chats')
          .select()
          .eq('id', chatId)
          .maybeSingle();
      
      if (chatResponse == null) {
        // Create new chat
        await _supabase.from('chats').insert({
          'id': chatId,
          'participants': participants,
          'listing_id': listingId,
          'listing_title': listingTitle,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'last_message': '',
          // Some databases may not have last_message_time/last_message_sender_id
          // We keep updated_at for ordering, and set optional fields only when present
          'last_message_sender_id': '',
          'is_active': true,
          'unread_count': {
            user.id: 0,
            otherUserId: 0,
          }
        });
      }

      return chatId;
    } catch (e) {
      AppLogger.e('Error creating/getting chat', e);
      return null;
    }
  }

  // Legacy method for backward compatibility
  static Future<String?> startChat({
    required String listingId,
    required String listingTitle,
    required String listingImage,
    required String sellerId,
    required String sellerName,
  }) async {
    return createOrGetChat(
      otherUserId: sellerId,
      listingId: listingId,
      listingTitle: listingTitle,
    );
  }

  /// Send a message in a chat
  static Future<bool> sendMessage({
    required String chatId,
    required String content,
    String type = 'text', // 'text', 'image', 'listing'
    Map<String, dynamic>? metadata, // unused if metadata column absent
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Add message to messages table
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Try primary chat_messages table first
      final basePayload = {
        'id': messageId,
        'chat_id': chatId,
        'sender_id': user.id,
        'content': content,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'is_edited': false,
        'is_deleted': false,
      };
      try {
        await _supabase.from('chat_messages').insert(basePayload);
      } catch (e) {
        try {
          await _supabase.from('messages').insert(basePayload);
        } catch (e2) {
          AppLogger.e('Error inserting chat message into both tables (no metadata cols): $e / $e2');
          return false;
        }
      }

      // Update chat with last message info
      final chatResponse = await _supabase
          .from('chats')
          .select('participants, unread_count')
          .eq('id', chatId)
          .maybeSingle();
      if (chatResponse == null) {
        return true; // message inserted, but chat fetch failed (avoid user-facing failure)
      }
      
      final participants = List<String>.from(chatResponse['participants'] ?? []);
      final otherUserId = participants.firstWhere((id) => id != user.id);
      
      final Map<String, dynamic> unreadCount = Map<String, dynamic>.from(chatResponse['unread_count'] ?? {});
      unreadCount[otherUserId] = (unreadCount[otherUserId] ?? 0) + 1;
      unreadCount[user.id] = 0; // Reset sender's unread count

      final updates = {
        'last_message': content,
        'last_message_time': DateTime.now().toIso8601String(),
        'last_message_sender_id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
        'unread_count': unreadCount,
      };
      try {
        await _supabase.from('chats').update(updates).eq('id', chatId);
      } catch (e) {
        // Fallback if last_message_time column doesn't exist
        final fallback = Map<String, dynamic>.from(updates)..remove('last_message_time');
        try {
          await _supabase.from('chats').update(fallback).eq('id', chatId);
        } catch (_) {
          // As a last resort, update minimal fields
          await _supabase.from('chats').update({
            'last_message': content,
            'updated_at': DateTime.now().toIso8601String(),
            'unread_count': unreadCount,
          }).eq('id', chatId);
        }
      }

      return true;
    } catch (e) {
      AppLogger.e('Error sending message', e);
      return false;
    }
  }

  /// Get user's chats
  static Stream<List<Map<String, dynamic>>> getUserChats() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value([]);

  final stream = _supabase
    .from('chats')
    .stream(primaryKey: ['id']);

  // We avoid hard-failing if the column is absent by sorting client-side anyway.
  return stream.map((data) {
      // Filter chats where user is a participant
      final filtered = data.where((chat) {
        final participants = List<String>.from(chat['participants'] ?? []);
        return participants.contains(user.id) && (chat['is_active'] ?? false);
      }).map((chat) => Map<String, dynamic>.from(chat)).toList();

      // Sort client-side using best available timestamp to avoid DB dependency
      int compareByTime(Map<String, dynamic> a, Map<String, dynamic> b) {
        DateTime parseTs(Map<String, dynamic> m) {
          String? ts = m['last_message_time'] ?? m['updated_at'] ?? m['created_at'];
          try {
            if (ts is String && ts.isNotEmpty) return DateTime.parse(ts);
          } catch (_) {}
          return DateTime.fromMillisecondsSinceEpoch(0);
        }

        final ta = parseTs(a);
        final tb = parseTs(b);
        return tb.compareTo(ta); // desc
      }

      filtered.sort(compareByTime);
      return filtered;
    });
  }

  /// Get messages in a chat
  static Stream<List<Map<String, dynamic>>> getChatMessages(String chatId, {int limit = 50}) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit)
        .map((data) {
      // Filter messages for the specific chat and not deleted
      return data.where((message) {
        return message['chat_id'] == chatId && !(message['is_deleted'] ?? false);
      }).map((message) {
        return Map<String, dynamic>.from(message);
      }).toList();
    });
  }

  /// Mark messages as read
  static Future<bool> markMessagesAsRead(String chatId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Mark messages as read directly
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', user.id)
          .eq('is_read', false);

      // Get current chat data to update unread count
      final chatResponse = await _supabase
          .from('chats')
          .select('unread_count')
          .eq('id', chatId)
          .single();

      final Map<String, dynamic> unreadCount = Map<String, dynamic>.from(chatResponse['unread_count'] ?? {});
      unreadCount[user.id] = 0;

      // Reset unread count for current user
      await _supabase
          .from('chats')
          .update({'unread_count': unreadCount})
          .eq('id', chatId);

      return true;
    } catch (e) {
      AppLogger.e('Error marking messages as read', e);
      return false;
    }
  }

  /// Get total unread messages count
  static Stream<int> getTotalUnreadCount() {
    final user = _supabase.auth.currentUser;
    if (user == null) return Stream.value(0);

    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((data) {
      int totalUnread = 0;
      for (final chat in data) {
        final participants = List<String>.from(chat['participants'] ?? []);
        if (participants.contains(user.id) && (chat['is_active'] ?? false)) {
          final unreadCount = Map<String, dynamic>.from(chat['unread_count'] ?? {});
          totalUnread += (unreadCount[user.id] ?? 0) as int;
        }
      }
      return totalUnread;
    });
  }
}

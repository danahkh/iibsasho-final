import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/chat.dart';
import 'notification_service.dart';
import '../utils/app_logger.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  // Get all chats for a user (as either seller or buyer)
  static Stream<List<Chat>> getUserChats(String userId) {
    try {
      // Get chats as seller and combine with chats as buyer
      return _supabase
          .from('chats')
          .stream(primaryKey: ['id'])
          .eq('seller_id', userId)
          .order('last_message_time', ascending: false)
          .asyncMap((sellerData) async {
            // Also get chats where user is the buyer
            final buyerData = await _supabase
                .from('chats')
                .select()
                .eq('buyer_id', userId)
                .order('last_message_time', ascending: false);

            // Combine and deduplicate chats
            final allChats = <String, dynamic>{};
            
            // Add seller chats
            for (final chat in sellerData) {
              allChats[chat['id']] = _normalizeChatMap(chat, userId);
            }
            
            // Add buyer chats (avoid duplicates)
            for (final chat in buyerData) {
              allChats[chat['id']] = _normalizeChatMap(chat, userId);
            }

            // Convert to Chat objects and sort by last_message_time
            final chatList = allChats.values
                .map((chat) => Chat.fromMap(chat))
                .toList();
            
            chatList.sort((a, b) => 
                b.lastMessageTime.compareTo(a.lastMessageTime));

            return chatList;
          });
    } catch (e) {
      AppLogger.e('getUserChats failed', e);
      return Stream.value([]);
    }
  }

  // Ensure types align with Chat model expectations
  static Map<String, dynamic> _normalizeChatMap(Map<String, dynamic> chat, String currentUserId) {
    final m = Map<String, dynamic>.from(chat);
    // Normalize unread_count to an int for current user
    final unread = m['unread_count'];
    int myUnread = 0;
    if (unread is int) {
      myUnread = unread;
    } else if (unread is String) {
      myUnread = int.tryParse(unread) ?? 0;
    } else if (unread is Map) {
      final val = unread[currentUserId];
      if (val is int) myUnread = val; else if (val is String) myUnread = int.tryParse(val) ?? 0;
    }
    m['unread_count'] = myUnread;
    // Ensure last_message_time exists for sorting
    if (m['last_message_time'] == null || (m['last_message_time'] is String && (m['last_message_time'] as String).isEmpty)) {
      m['last_message_time'] = m['updated_at'] ?? m['created_at'] ?? DateTime.now().toIso8601String();
    }
    // Ensure listing_title is string
    if (m['listing_title'] == null) m['listing_title'] = '';
    return m;
  }

  // Create a new chat
  static Future<Chat?> createChat({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required String listingTitle,
  }) async {
    try {
      // Check if chat already exists
      final existingChat = await _supabase
          .from('chats')
          .select()
          .eq('listing_id', listingId)
          .eq('seller_id', sellerId)
          .eq('buyer_id', buyerId)
          .maybeSingle();

      if (existingChat != null) {
        // Normalize potential JSON objects that the model can't parse directly
        final normalized = _normalizeChatMap(Map<String, dynamic>.from(existingChat), buyerId);
        return Chat.fromMap(normalized);
      }

      // Create new chat (be resilient to schema differences)
      final nowIso = DateTime.now().toIso8601String();
      try {
        final response = await _supabase.from('chats').insert({
          'listing_id': listingId,
          'seller_id': sellerId,
          'buyer_id': buyerId,
          'listing_title': listingTitle,
          'last_message': 'Chat started',
          'last_message_time': nowIso,
          // Prefer per-user map when supported; backend will ignore if schema differs
          'unread_count': {sellerId: 0, buyerId: 0},
          'created_at': nowIso,
        }).select().single();
        return Chat.fromMap(_normalizeChatMap(response, buyerId));
      } catch (e) {
        // Fallback: insert minimal required fields
        try {
          final response = await _supabase.from('chats').insert({
            'listing_id': listingId,
            'seller_id': sellerId,
            'buyer_id': buyerId,
            'created_at': nowIso,
          }).select().single();
          // Optionally update listing_title/last_message if columns exist
          try {
            await _supabase.from('chats').update({
              if (listingTitle.isNotEmpty) 'listing_title': listingTitle,
              'last_message': 'Chat started',
              'last_message_time': nowIso,
            }).eq('id', response['id']);
          } catch (_) {}
          return Chat.fromMap(_normalizeChatMap(response, buyerId));
        } catch (e2) {
          AppLogger.e('createChat minimal insert failed', e2);
          return null;
        }
      }
    } catch (e) {
      AppLogger.e('createChat failed', e);
      return null;
    }
  }

  // Send a message
  static Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      // Primary: chat_messages table with 'content' + 'created_at'
      try {
        await _supabase.from('chat_messages').insert({
          'chat_id': chatId,
          'sender_id': senderId,
          'content': message,
          'type': type,
          if (metadata != null) 'metadata': metadata,
          'created_at': nowIso,
          'is_read': false,
        });
      } catch (e) {
        // Fallback 1: messages table shaped like new schema (content/created_at)
        try {
          await _supabase.from('messages').insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'content': message,
            'type': type,
            if (metadata != null) 'metadata': metadata,
            'created_at': nowIso,
            'is_read': false,
          });
        } catch (e1) {
          // Fallback 2: legacy messages table (message/timestamp)
          try {
            await _supabase.from('messages').insert({
              'chat_id': chatId,
              'sender_id': senderId,
              'message': message,
              'type': type,
              if (metadata != null) 'metadata': metadata,
              'timestamp': nowIso,
              'is_read': false,
            });
          } catch (e2) {
            AppLogger.e('sendMessage dual insert failed', e2);
            return false;
          }
        }
      }

      // Update chat last message/time and best-effort unread_count
      try {
        final chatData = await _supabase
            .from('chats')
            .select('seller_id, buyer_id, unread_count')
            .eq('id', chatId)
            .maybeSingle();

        Map<String, dynamic> updates = {
          'last_message': message,
          'last_message_time': nowIso,
          'updated_at': nowIso,
        };

        if (chatData != null) {
          final sellerId = chatData['seller_id']?.toString();
          final buyerId = chatData['buyer_id']?.toString();
          final otherId = senderId == sellerId ? buyerId : sellerId;
          if (otherId != null) {
            final Map<String, dynamic> unread =
                Map<String, dynamic>.from(chatData['unread_count'] ?? {});
            final currentOther = unread[otherId];
            int otherCount = 0;
            if (currentOther is int) otherCount = currentOther;
            if (currentOther is String) {
              otherCount = int.tryParse(currentOther) ?? 0;
            }
            unread[otherId] = otherCount + 1;
            // Reset sender unread to 0 where applicable
            unread[senderId] = 0;
            updates['unread_count'] = unread;
          }
        }

        await _supabase.from('chats').update(updates).eq('id', chatId);
      } catch (e) {
        // Fallback minimal update to avoid failing message
        try {
          await _supabase
              .from('chats')
              .update({'last_message': message, 'last_message_time': nowIso})
              .eq('id', chatId);
        } catch (_) {}
      }

  // Send notification to recipient (best-effort; ignore schema diffs)
      try {
        final chatResponse = await _supabase
            .from('chats')
            .select('seller_id, buyer_id')
            .eq('id', chatId)
            .single();
            
        final recipientId = chatResponse['seller_id'] == senderId 
            ? chatResponse['buyer_id'] 
            : chatResponse['seller_id'];
        
        final senderResponse = await _supabase
            .from('users')
            .select('name, display_name')
            .eq('id', senderId)
            .single();
            
        final senderName = senderResponse['name'] ?? senderResponse['display_name'] ?? 'Someone';
        
        // Try to get listing title if present on chat for richer notification
        String listingTitle = '';
        try {
          final listingData = await _supabase
              .from('chats')
              .select('listing_title')
              .eq('id', chatId)
              .maybeSingle();
          if (listingData != null) listingTitle = listingData['listing_title'] ?? '';
        } catch (_) {}
        await NotificationService.sendMessageNotification(
          recipientId: recipientId,
          senderName: senderName,
          chatId: chatId,
          listingTitle: listingTitle,
        );
      } catch (e) {
        AppLogger.w('sendMessage notification failed: $e');
        // Don't fail the message if notification fails
      }

      return true;
    } catch (e) {
  AppLogger.e('sendMessage failed', e);
      return false;
    }
  }

  // Get messages for a chat
  static Stream<List<Message>> getChatMessages(String chatId) {
    // Try primary chat_messages stream; if schema mismatch occurs, fallback to legacy messages
    try {
      return _supabase
          .from('chat_messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
          .order('created_at', ascending: true)
          .map((data) => data.map((m) => Message.fromMap(_normalizeMessageMap(m))).toList());
    } catch (_) {
    return _supabase
          .from('messages')
          .stream(primaryKey: ['id'])
          .eq('chat_id', chatId)
      // Order by created_at when available (newer schema); fallback to timestamp
      .order('created_at', ascending: true)
          .map((data) => data.map((m) => Message.fromMap(_normalizeMessageMap(m))).toList());
    }
  }

  static Map<String, dynamic> _normalizeMessageMap(Map<String, dynamic> m) {
    if (m.containsKey('content') && !m.containsKey('message')) {
      m = Map<String, dynamic>.from(m);
      m['message'] = m['content'];
    }
    if (m.containsKey('created_at') && !m.containsKey('timestamp')) {
      m = Map<String, dynamic>.from(m);
      m['timestamp'] = m['created_at'];
    }
    return m;
  }

  // Mark messages as read
  static Future<bool> markMessagesAsRead(String chatId, String userId) async {
    bool ok = false;
    try {
      // Try primary table first
      try {
        await _supabase
            .from('chat_messages')
            .update({'is_read': true})
            .eq('chat_id', chatId)
            .neq('sender_id', userId);
        ok = true;
      } catch (e) {
        // Fallback to legacy table name
        try {
          await _supabase
              .from('messages')
              .update({'is_read': true})
              .eq('chat_id', chatId)
              .neq('sender_id', userId);
          ok = true;
        } catch (e2) {
          AppLogger.e('markMessagesAsRead dual-table update failed', e2);
        }
      }

      // Reset unread count for this user in this chat if JSON map exists (best-effort)
      try {
        final chat = await _supabase
            .from('chats')
            .select('unread_count')
            .eq('id', chatId)
            .maybeSingle();
        if (chat != null && chat['unread_count'] != null) {
          final uc = Map<String, dynamic>.from(chat['unread_count'] as Map);
          uc[userId] = 0;
          await _supabase
              .from('chats')
              .update({'unread_count': uc})
              .eq('id', chatId);
        }
      } catch (e) {
        AppLogger.w('markMessagesAsRead: unread_count update skipped: $e');
      }

      return ok;
    } catch (e) {
      AppLogger.e('markMessagesAsRead failed', e);
      return false;
    }
  }

  // Delete a chat
  static Future<bool> deleteChat(String chatId) async {
    try {
      // Delete all messages first
      await _supabase.from('messages').delete().eq('chat_id', chatId);
      // Delete chat
      await _supabase.from('chats').delete().eq('id', chatId);
      return true;
    } catch (e) {
      AppLogger.e('deleteChat failed', e);
      return false;
    }
  }
}

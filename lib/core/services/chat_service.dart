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
              allChats[chat['id']] = chat;
            }
            
            // Add buyer chats (avoid duplicates)
            for (final chat in buyerData) {
              allChats[chat['id']] = chat;
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
        return Chat.fromMap(existingChat);
      }

      // Create new chat
      final response = await _supabase.from('chats').insert({
        'listing_id': listingId,
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'listing_title': listingTitle,
        'last_message': 'Chat started',
        'last_message_time': DateTime.now().toIso8601String(),
        'unread_count': 0,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Chat.fromMap(response);
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
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      // Primary: chat_messages table with 'content' + 'created_at'
      try {
        await _supabase.from('chat_messages').insert({
          'chat_id': chatId,
          'sender_id': senderId,
          'content': message,
          'created_at': nowIso,
          'is_read': false,
        });
      } catch (e) {
        // Fallback legacy schema: messages table with 'message' + 'timestamp'
        try {
          await _supabase.from('messages').insert({
            'chat_id': chatId,
            'sender_id': senderId,
            'message': message,
            'timestamp': nowIso,
            'is_read': false,
          });
        } catch (e2) {
          AppLogger.e('sendMessage dual insert failed', e2);
          return false;
        }
      }

      await _supabase.from('chats').update({
        'last_message': message,
        'last_message_time': nowIso,
      }).eq('id', chatId);

      // Send notification to recipient
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
          .order('timestamp', ascending: true)
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
    try {
      await _supabase
          .from('messages')
          .update({'is_read': true})
          .eq('chat_id', chatId)
          .neq('sender_id', userId);

      // Reset unread count for this chat
      await _supabase
          .from('chats')
          .update({'unread_count': 0})
          .eq('id', chatId);

      return true;
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

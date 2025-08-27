import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/Message.dart';

class MessageService {
  final SupabaseClient supabase = Supabase.instance.client;

  Stream<List<Message>> getMessagesForChat(String chatId) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp')
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
  }
}

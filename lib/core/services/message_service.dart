<<<<<<< HEAD
import '../model/Message.dart';

class MessageService {
  static Stream<List<Message>> getMessagesForChat(String chatId) {
    return const Stream.empty(); // TODO: Implement Supabase realtime
=======
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/Message.dart';

class MessageService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<Message>> getMessagesForChat(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp')
        .map((data) => data.map((item) => Message.fromJson(item)).toList());
>>>>>>> c9b83a2 (Backup and sync: create local backup folder and prepare push to final repo)
  }
}

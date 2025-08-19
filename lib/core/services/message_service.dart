import '../model/Message.dart';

class MessageService {
  static Stream<List<Message>> getMessagesForChat(String chatId) {
    return const Stream.empty(); // TODO: Implement Supabase realtime
  }
}

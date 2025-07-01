import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/Message.dart';

class MessageService {
  Stream<List<Message>> getMessagesForChat(String chatId) {
    return FirebaseFirestore.instance
      .collection('chats')
      .doc(chatId)
      .collection('messages')
      .orderBy('timestamp')
      .snapshots()
      .map((snapshot) => snapshot.docs
        .map((doc) => Message.fromJson(doc.data()))
        .toList());
  }
}

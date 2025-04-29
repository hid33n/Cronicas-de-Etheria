import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guild/models/chat_message.dart';

class GlobaChatServices {
  final _globalCollection = FirebaseFirestore.instance
      .collection('chats')
      .doc('global')
      .collection('messages')
      .withConverter<ChatMessage>(
        fromFirestore:
            (snapshot, options) => ChatMessage.fromDoc(snapshot.data()!),
        toFirestore: (value, options) => value.toJson(),
      );

  CollectionReference<ChatMessage> _getGremioChat(String cityId) =>
      FirebaseFirestore.instance
          .collection('chats')
          .doc(cityId)
          .collection('messages')
          .withConverter<ChatMessage>(
            fromFirestore:
                (snapshot, options) => ChatMessage.fromDoc(snapshot.data()!),
            toFirestore: (value, options) => value.toJson(),
          );

  Stream<List<ChatMessage>> getGlobalMessages() {
    return _globalCollection
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => doc.data())
                  .whereType<ChatMessage>()
                  .toList(),
        );
  }

  Stream<List<ChatMessage>> geGremioMessages(String cityId) {
    return _getGremioChat(cityId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) =>
              snap.docs
                  .map((doc) => doc.data())
                  .whereType<ChatMessage>()
                  .toList(),
        );
  }
}

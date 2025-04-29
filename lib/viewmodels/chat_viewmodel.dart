import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class ChatViewModel extends ChangeNotifier {
  final _firestore = FirebaseFirestore.instance;
  final _globalCol = FirebaseFirestore.instance.collection('global_chat');
  List<QueryDocumentSnapshot> _messages = [];
  List<ChatMessage> globalMessages = [];
  List<ChatMessage> cityMessages = [];
  int get unreadGlobalCount =>
      _messages.where((m) => !(m.data() as Map)['read'] as bool).length;
  StreamSubscription? _globalSub;
  StreamSubscription? _citySub;

  //   void initGlobalChat() {
  //   _globalSub?.cancel();
  //   _globalSub = _firestore
  //       .collection('chats')
  //       .doc('global')
  //       .collection('messages')
  //       .orderBy('timestamp', descending: false)
  //       .snapshots()
  //       .listen((snap) {
  //     try {
  //       globalMessages = snap.docs.map(ChatMessage.fromDoc).toList();
  //       notifyListeners();
  //     } catch (e, s) {
  //       debugPrint('Error al procesar mensajes: $e');
  //       debugPrintStack(stackTrace: s);
  //     }
  //   });
  // }

  // /// Inicia el listener para el chat de una ciudad (gremio)
  // void initCityChat(String cityId) {
  //   _citySub?.cancel();
  //   _citySub = _firestore
  //       .collection('chats')
  //       .doc(cityId)
  //       .collection('messages')
  //       .orderBy('timestamp', descending: false)
  //       .snapshots()
  //       .listen((snap) {
  //     cityMessages = snap.docs.map(ChatMessage.fromDoc).toList();
  //     notifyListeners();
  //   });
  // }

  /// Envía un mensaje al chat global
  Future<void> sendGlobalMessage({
    required String userId,
    required String userName,
    required String text,
  }) {
    final ref = _firestore
        .collection('chats')
        .doc('global')
        .collection('messages');
    return ref.add({
      'senderId': userId,
      'senderName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Envía un mensaje al chat de ciudad
  Future<void> sendCityMessage({
    required String cityId,
    required String userId,
    required String userName,
    required String text,
  }) {
    final ref = _firestore
        .collection('chats')
        .doc(cityId)
        .collection('messages');
    return ref.add({
      'senderId': userId,
      'senderName': userName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllGlobalRead() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in _messages) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['read'] == false) {
        batch.update(_globalCol.doc(doc.id), {'read': true});
      }
    }
    await batch.commit();
    // luego refresca local:
    for (var doc in _messages) {
      (doc.data() as Map)['read'] = true;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _globalSub?.cancel();
    _citySub?.cancel();
    super.dispose();
  }
}

// lib/services/presence_service.dart

import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final String uid;
  final DatabaseReference _statusRef;
  final DatabaseReference _connectedRef;

  PresenceService(this.uid)
      : _statusRef = FirebaseDatabase.instance.ref('status/$uid'),
        _connectedRef = FirebaseDatabase.instance.ref('.info/connected');

  /// Debe llamarse justo después de hacer login
  void goOnline(String name) {
    _statusRef.onDisconnect().set({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
      'name': name,
    });
    _statusRef.set({
      'state': 'online',
      'last_changed': ServerValue.timestamp,
      'name': name,
    });
  }

  /// Opcional: marcar offline manual (por ejemplo al hacer logout)
  Future<void> goOffline(String name) {
    return _statusRef.set({
      'state': 'offline',
      'last_changed': ServerValue.timestamp,
      'name': name,
    });
  }
}

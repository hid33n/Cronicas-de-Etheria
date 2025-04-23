// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream de cambios de estado de autenticación.
  Stream<User?> authChanges() => _auth.authStateChanges();

  /// Inicia sesión con email y contraseña.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

  /// Crea usuario con email y contraseña.
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

  /// Cierra sesión.
  Future<void> signOut() => _auth.signOut();

  /// Obtiene el usuario actual.
  User? get currentUser => _auth.currentUser;
}

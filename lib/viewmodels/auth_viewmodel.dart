// lib/viewmodels/auth_viewmodel.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:guild/data/building_catalog.dart';
import '../models/user_model.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
class AuthViewModel extends ChangeNotifier {
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  UserModel? _user;
  UserModel? get user => _user;

  AuthViewModel() {
    // Recargamos usuario cuando cambia el estado de autenticación
    _auth.authStateChanges().listen((fbUser) {
      if (fbUser != null) {
        loadCurrentUser();
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }
   Future<void> updateAvatar(String url) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      // 1) Actualizar Firestore
      await _firestore.collection('users').doc(uid).update({
        'avatarUrl': url,
      });
      // 2) Actualizar modelo en memoria
      if (_user != null) {
        _user!.avatarUrl = url;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al actualizar avatarUrl: $e');
      rethrow;
    }
  }

 Future<void> updateAvatarUrl(String url) {
    return _updateField<String>('avatarUrl', url);
  }

  /// Carga inicialmente si ya hay sesión activa.
  Future<void> loadCurrentUser() async {
    final fbUser = _auth.currentUser;
    if (fbUser != null) {
      await _loadUserFromFirestore(fbUser.uid);
    }
  }
// lib/viewmodels/auth_viewmodel.dart

/// Inicia sesión con email O con nombre de aventurero + password.
Future<void> signIn(String identifier, String password) async {
  String emailToUse;

  // 1) Determinar si es email o nombre de usuario
  if (identifier.contains('@')) {
    emailToUse = identifier.trim();
  } else {
    // buscar el documento de usuario con ese nombre
    final query = await _firestore
      .collection('users')
      .where('name', isEqualTo: identifier)
      .limit(1)
      .get();

    if (query.docs.isEmpty) {
      throw Exception('No existe un usuario con el nombre \"$identifier\".');
    }
    emailToUse = query.docs.first.data()['email'] as String;
  }

  // 2) Intentar login con el email resuelto
  try {
    final cred = await _auth.signInWithEmailAndPassword(
      email: emailToUse,
      password: password,
    );
    // 3) Cargar perfil desde Firestore
    await _loadUserFromFirestore(cred.user!.uid);
  } on FirebaseAuthException catch (e) {
    // mensajes más amigables
    if (e.code == 'user-not-found') {
      throw Exception('No se encontró esa cuenta.');
    } else if (e.code == 'wrong-password') {
      throw Exception('Contraseña incorrecta.');
    }
    rethrow;
  }
}


 // lib/viewmodels/auth_viewmodel.dart

Future<void> uploadAvatar() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) throw Exception('No hay usuario conectado.');

    // 1) Selección de imagen
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (picked == null) return; // usuario canceló

    final file = File(picked.path);

    // 2) Subida a Firebase Storage
    final storageRef = FirebaseStorage.instance.ref().child('avatars/${fbUser.uid}.jpg');
    final uploadTask = storageRef.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    final snapshot = await uploadTask.whenComplete(() {});

    // 3) Obtener URL pública
    final avatarUrl = await snapshot.ref.getDownloadURL();

    // 4) Guardar en Firestore
    await _firestore.collection('users').doc(fbUser.uid).update({
      'avatarUrl': avatarUrl,
    });

    // 5) Actualizar modelo local y notificar
    _user?.avatarUrl = avatarUrl;
    notifyListeners();
  }


Future<void> signUp(String name, String email, String password, String raceId) async {
  // 1) Validar que el nombre no exista ya en Firestore
  final nameQuery = await _firestore
      .collection('users')
      .where('name', isEqualTo: name)
      .get();
  if (nameQuery.docs.isNotEmpty) {
    throw Exception('El nombre de aventurero "$name" ya está en uso.');
  }

  try {
    // 2) Intentar crear el usuario en FirebaseAuth
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // 3) Creamos el documento /users/{uid}
    await _firestore.collection('users').doc(uid).set({
      'name':      name,
      'email':     email.trim(),
      'cityId':    null,
      'gold':      0,
      'rank':      'Ciudadano',
      'race':      raceId,
      'avatarUrl': '',
      'missionsCompleted': 0,
      'achievements':      <String>[],
      'eloRating': 1000,
    });

    // 4) Edificios y recursos iniciales
    final bColl = _firestore.collection('users').doc(uid).collection('buildings');
    final rColl = _firestore.collection('users').doc(uid).collection('resources');
    for (final b in kBuildingCatalog.values) {
      await bColl.doc(b.id).set({'level': 1, 'readyAt': null});
    }
    await rColl.doc('wood').set({'qty': 1500});
    await rColl.doc('stone').set({'qty': 1500});
    await rColl.doc('food').set({'qty': 1500});

    // 5) Cargar en memoria
    _user = UserModel(
      id:        uid,
      name:      name,
      avatarUrl: '',
      cityId:    null,
      gold:      0,
      race:      raceId,
      missionsCompleted: 0,
      eloRating: 1000,
      achievements:      [],
      
    );
    notifyListeners();

  } on FirebaseAuthException catch (e) {
    // 6) Capturar error de email duplicado
    if (e.code == 'email-already-in-use') {
      throw Exception('El correo "$email" ya está registrado. Por favor inicia sesión.');
    }
    rethrow;
  }
}

  /// Cierra sesión en Firebase y limpia el modelo local.
  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

 // lib/viewmodels/auth_viewmodel.dart
Future<void> _loadUserFromFirestore(String uid) async {
  final docRef = _firestore.collection('users').doc(uid);
  final snap   = await docRef.get();

  // Si no existe, creamos con 'race' por defecto ('human' en este ejemplo)
  if (!snap.exists || snap.data() == null) {
    final fbUser = _auth.currentUser!;
    final defaultName = fbUser.displayName
        ?? fbUser.email?.split('@').first
        ?? 'Forastero';
    const defaultRace = 'human';

    await docRef.set({
      'name': defaultName,
      'email': fbUser.email,
      'avatarUrl': '',
      'cityId': null,
      'gold': 0,
      'rank': 'Ciudadano',
      'race': defaultRace,
      'missionsCompleted': 0,
      'eloRating': 1000,
      'achievements': <String>[],
    });

    _user = UserModel(
      id: uid,
      name: defaultName,
      avatarUrl: '',
      cityId: null,
      gold: 0,
      race: defaultRace,
      missionsCompleted: 0,
      achievements: [],
      eloRating: 1000,
    );
    notifyListeners();
    return;
  }

  // Si existe, cargamos sus datos, incluyendo la 'race'
  final data = snap.data()!;
  final storedRace = data['race'] as String? ?? 'human';

  _user = UserModel(
    id: uid,
    name: data['name'] as String,
    avatarUrl: data['avatarUrl'] as String? ?? '',
    cityId: data['cityId'] as String?,
    gold: data['gold'] as int? ?? 0,
    race: storedRace,
    missionsCompleted: data['missionsCompleted'] as int? ?? 0,
    achievements: List<String>.from(data['achievements'] as List? ?? []),
    eloRating: data['eloRating'] as int? ?? 1000,
  );
  notifyListeners();
}


  Future<void> _updateField<T>(String field, T value) async {
  final uid = _auth.currentUser?.uid;
  if (uid == null) return;
  try {
    // 1) Subo SOLO el campo solicitado
    await _firestore.collection('users').doc(uid).update({ field: value });

    // 2) Actualizo el modelo local según el campo
    switch (field) {
      case 'cityId':
        _user?.cityId = value as String?;
        break;
      case 'gold':
        _user?.gold = value as int;
        break;
      case 'avatarUrl':
        _user?.avatarUrl = value as String;
        break;
      case 'missionsCompleted':
        _user?.missionsCompleted = value as int;
        break;
      case 'achievements':
        _user?.achievements = List<String>.from(value as List);
        break;
      case 'race':
        _user?.race = value as String;
        break;

      // ← Nuevo: manejo de cambios de Elo
      case 'eloRating':
        _user?.eloRating = value as int;
        break;

      // ← Elimino el case 'rank'
    }

    notifyListeners();
  } catch (e) {
    debugPrint('AuthViewModel: error al actualizar $field: $e');
  }
}

   /// Incrementa el contador de misiones completadas en 1
 Future<void> incrementMissionsCompleted() =>
     _updateField<int>('missionsCompleted', (_user?.missionsCompleted ?? 0) + 1);

 /// Añade un logro a la lista
 Future<void> addAchievement(String trophy) async {
   final nuevaLista = [...?_user?.achievements, trophy];
   return _updateField<List<String>>('achievements', nuevaLista);
 }

  /// Actualiza solo el cityId (ej. al unirse o salir de un gremio).
  Future<void> setCityId(String? cityId) => _updateField<String?>('cityId', cityId);

  /// Actualiza el oro del usuario.
  Future<void> updateGold(int newGold) => _updateField<int>('gold', newGold);

  /// Actualiza el rango del usuario.
  Future<void> updateRank(String newRank) => _updateField<String>('rank', newRank);
}

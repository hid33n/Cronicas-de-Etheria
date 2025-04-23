// lib/services/user_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guild/data/building_catalog.dart';
import 'package:guild/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Carga (o crea) el documento de usuario en Firestore.
  Future<UserModel> loadUser(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final snap = await docRef.get();

    if (!snap.exists || snap.data() == null) {
      // Crear con valores por defecto
      final fbEmail = uid; // Asume que tienes el email en otro lugar si lo necesitas
      const defaultRace = 'human';
      final defaultName = 'Forastero';

      await docRef.set({
        'name': defaultName,
        'email': fbEmail,
        'avatarUrl': '',
        'cityId': null,
        'gold': 0,
        'race': defaultRace,
        'missionsCompleted': 0,
        'eloRating': 1000,
        'achievements': <String>[],
      });

      // Inicializar edificios y recursos
      final bColl = docRef.collection('buildings');
      final rColl = docRef.collection('resources');
      for (final b in kBuildingCatalog.values) {
        await bColl.doc(b.id).set({'level': 1, 'readyAt': null});
      }
      await rColl.doc('wood').set({'qty': 1500});
      await rColl.doc('stone').set({'qty': 1500});
      await rColl.doc('food').set({'qty': 1500});

      return UserModel(
        id: uid,
        name: defaultName,
        avatarUrl: '',
        cityId: null,
        gold: 0,
        race: defaultRace,
        missionsCompleted: 0,
        eloRating: 1000,
        achievements: [],
      );
    }

    final data = snap.data()!;
    return UserModel(
      id: uid,
      name: data['name'] as String,
      avatarUrl: data['avatarUrl'] as String? ?? '',
      cityId: data['cityId'] as String?,
      gold: data['gold'] as int? ?? 0,
      race: data['race'] as String? ?? 'human',
      missionsCompleted: data['missionsCompleted'] as int? ?? 0,
      eloRating: data['eloRating'] as int? ?? 1000,
      achievements: List<String>.from(data['achievements'] as List? ?? []),
    );
  }

  /// Actualiza uno o varios campos del usuario.
  Future<void> updateFields(String uid, Map<String, dynamic> fields) {
    return _firestore.collection('users').doc(uid).update(fields);
  }

  /// Consulta de usuario por nombre (para login por username).
  Future<String?> getEmailByUsername(String name) async {
    final query = await _firestore
        .collection('users')
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    return query.docs.first.data()['email'] as String?;
  }
}

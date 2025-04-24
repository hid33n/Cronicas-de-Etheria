// lib/viewmodels/city_viewmodel.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/city_model.dart';

class GuildViewmodel extends ChangeNotifier {
  // Constantes de posicionamiento
  static const double _minDistance = 50.0;
  static const double _mapSize     = 1200.0;

  final Random _rng = Random();

  final _cityCol = FirebaseFirestore.instance.collection('cities');
  final _userCol = FirebaseFirestore.instance.collection('users');

  // Lista local de CityModel
  final List<CityModel> _cities = [];
  List<CityModel> get cities => List.unmodifiable(_cities);

  GuildViewmodel() {
    // Escucha en tiempo real los cambios en 'cities'
    _cityCol.snapshots().listen(
      _onCitySnapshot,
      onError: (e) => debugPrint('GuildViewmodel: error escuchando cities: $e'),
    );
  }

  /// Mapea cada snapshot de Firestore a CityModel
  void _onCitySnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _cities
      ..clear()
      ..addAll(snap.docs.map((doc) {
        final data = doc.data();
        return CityModel(
          id: doc.id,
          name: data['name'] as String? ?? 'Sin nombre',
          mayorId: data['mayorId'] as String? ?? '',
          taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.05,
          x: (data['x'] as num?)?.toDouble() ?? 0.0,
          y: (data['y'] as num?)?.toDouble() ?? 0.0,
         iconAsset: data['iconAsset'] as String? ?? 'assets/guild_icons/icon1.png',

          residents: List<String>.from(data['residents'] as List? ?? []),
          description: data['description'] as String? ?? '',
          trophies: data['trophies'] as int? ?? 0, 
        );
      }));
    notifyListeners();
  }

  /// Busca en la lista local la ciudad por su ID
  CityModel? getCityById(String id) {
    try {
      return _cities.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Crea un nuevo gremio en Firestore y retorna su ID, o null si falla.
  Future<String?> createGuild({
    required String name,
    required String mayorId,
    required String description,
    required int mayorElo,
    required String iconAsset,
  }) async {
    // Generar posición aleatoria sin solaparse
    double x, y;
    int tries = 0;
    do {
      x = _rng.nextDouble() * _mapSize;
      y = _rng.nextDouble() * _mapSize;
      tries++;
    } while (_overlaps(x, y) && tries < 100);

    final trophies = mayorElo ~/ 2; // trofeos = elo fundador ÷ 2

    try {
      final docRef = await _cityCol.add({
        'name':        name,
        'mayorId':     mayorId,
        'taxRate':     0.05,
        'x':           x,
        'y':           y,
        'iconAsset':   iconAsset, 
        'residents':   [mayorId],
        'description': description,
        'trophies':    trophies,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('GuildViewmodel: error creando guild: $e');
      return null;
    }
  }

 /// Une al usuario a un gremio. Devuelve true si tuvo éxito.
Future<bool> joinCity(String cityId, String userId) async {
  final current = await _getUserCityId(userId);
  if (current != null && current != cityId) {
    // Ya pertenece a otro gremio
    return false;
  }
  try {
    // 1) Añadir al usuario en la lista de residentes
    await _cityCol.doc(cityId).update({
      'residents': FieldValue.arrayUnion([userId]),
    });
    // 2) Actualizar su cityId en users
    await _userCol.doc(userId).update({'cityId': cityId});

    // 3) Recalcular trofeos tras el cambio
    await recalcTrophies(cityId);

    // 4) Notificar a la UI que algo cambió
    notifyListeners();
    return true;
  } catch (e) {
    debugPrint('GuildViewmodel: error al unirse: $e');
    return false;
  }
}



  /// Lee el campo 'cityId' del usuario en Firestore
  Future<String?> _getUserCityId(String userId) async {
    try {
      final doc = await _userCol.doc(userId).get();
      return doc.data()?['cityId'] as String?;
    } catch (e) {
      debugPrint('GuildViewmodel: error obteniendo cityId: $e');
      return null;
    }
  }
Future<void> recalcTrophies(String guildId) async {
  final city = getCityById(guildId);
  if (city == null) return;

  // 1) Obtén todos los documentos de usuario de los miembros
  final futures = city.residents.map((uid) => _userCol.doc(uid).get());
  final snaps   = await Future.wait(futures);

  // 2) Suma ½ del ELO de cada uno
  int newTrophies = 0;
  for (final snap in snaps) {
    final data = snap.data();
    if (data == null) continue;
    final elo = (data['eloRating'] as num?)?.toInt() ?? 0;
    newTrophies += (elo ~/ 2);
  }

  // 3) Guarda en Firestore
  await _cityCol.doc(guildId).update({'trophies': newTrophies});

  // 4) Refresca tu lista local: _onCitySnapshot lo hará en tiempo real,
  //    pero si quieres forzar un notify inmediatamente:
  final idx = _cities.indexWhere((c) => c.id == guildId);
  if (idx != -1) {
    _cities[idx] = _cities[idx].copyWith(trophies: newTrophies);
    notifyListeners();
  }
}
  /// El usuario abandona el gremio y luego se recálculan los trofeos.
Future<bool> leaveGuild(String guildId, String userId) async {
  try {
    // 1) Quitar al usuario de la lista de residentes
    await _cityCol.doc(guildId).update({
      'residents': FieldValue.arrayRemove([userId]),
    });
    // 2) Limpiar su cityId en users
    await _userCol.doc(userId).update({'cityId': null});

    // 3) Recalcular y guardar trofeos del gremio tras el cambio
    await recalcTrophies(guildId);

    return true;
  } catch (e) {
    debugPrint('Error leaveGuild: $e');
    return false;
  }
}


  /// Transfiere el cargo de alcalde a otro miembro
  Future<bool> transferLeadership(String guildId, String newMayorId) async {
    try {
      await _cityCol.doc(guildId).update({
        'mayorId': newMayorId,
      });
      return true;
    } catch (e) {
      debugPrint('Error transferLeadership: $e');
      return false;
    }
  }

  /// Disuelve completamente el gremio y quita el cityId a todos los miembros
  Future<bool> disbandGuild(String guildId) async {
    final doc = await _cityCol.doc(guildId).get();
    if (!doc.exists) return false;
    final residents = List<String>.from(doc.data()?['residents'] as List<dynamic>);
    final batch = FirebaseFirestore.instance.batch();
    for (var uid in residents) {
      batch.update(_userCol.doc(uid), {'cityId': null});
    }
    batch.delete(_cityCol.doc(guildId));
    try {
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint('Error disbandGuild: $e');
      return false;
    }
  }


  /// Comprueba si la posición (x,y) solapa a otra ciudad
  bool _overlaps(double x, double y) {
    return _cities.any((c) {
      final dx = c.x - x;
      final dy = c.y - y;
      return sqrt(dx * dx + dy * dy) < _minDistance;
    });
  }
}


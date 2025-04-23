// lib/viewmodels/city_viewmodel.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/city_model.dart';

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
      await _cityCol.doc(cityId).update({
        'residents': FieldValue.arrayUnion([userId]),
      });
      await _userCol.doc(userId).update({'cityId': cityId});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('GuildViewmodel: error al unirse: $e');
      return false;
    }
  }

  /// El usuario abandona el gremio. Devuelve true si tuvo éxito.
  Future<bool> leaveCity(String cityId, String userId) async {
    try {
      await _cityCol.doc(cityId).update({
        'residents': FieldValue.arrayRemove([userId]),
      });
      await _userCol.doc(userId).update({'cityId': null});
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('GuildViewmodel: error al salir: $e');
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

  
  /// El usuario simple abandona el gremio
  Future<bool> leaveGuild(String guildId, String userId) async {
    try {
      await _cityCol.doc(guildId).update({
        'residents': FieldValue.arrayRemove([userId]),
      });
      await _userCol.doc(userId).update({'cityId': null});
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


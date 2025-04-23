// lib/viewmodels/building_viewmodel.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:guild/data/building_catalog.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/models/unit_type.dart';

class BuildingViewModel extends ChangeNotifier {
  final _userCol = FirebaseFirestore.instance.collection('users');

  Map<String,int>      _levels = {};
  Map<String,DateTime?> _queue = {};
  Map<String,int>      _resources = {};

  Map<String,int> get levels    => _levels;
  Map<String,DateTime?> get queue => _queue;
  Map<String,int> get resources => _resources;

  StreamSubscription? _bSub;
  StreamSubscription? _rSub;

  void listenData(String uid) {
    _bSub?.cancel();
    _rSub?.cancel();

    _bSub = _userCol.doc(uid).collection('buildings').snapshots()
      .listen((snap) {
        _levels = {};
        _queue  = {};
        for (var d in snap.docs) {
          final data = d.data();
          _levels[d.id] = (data['level'] as int?) ?? 1;
          final ts = data['readyAt'] as Timestamp?;
          _queue[d.id] = ts?.toDate();
        }
        notifyListeners();
      });

    _rSub = _userCol.doc(uid).collection('resources').snapshots()
      .listen((snap) {
        _resources = {
          for (var d in snap.docs) d.id: (d.data()['qty'] as int? ?? 0)
        };
        notifyListeners();
      });
  }
Map<String,int> get productionPerHour {
  final rates = <String,int>{};
  // _levels viene de tu listener de edificios
  _levels.forEach((bid, lvl) {
    final b = kBuildingCatalog[bid];
    if (b != null && b.prodPerHour > 0) {
      // El edificio b.producción por hora * su nivel
      rates[bid] = b.prodPerHour * lvl;
    }
  });
  return rates;
}
 Future<String?> upgrade(String uid, String buildingId) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  final bType = kBuildingCatalog[buildingId]!;

  try {
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final u = await tx.get(userDoc);
      final lvl = (await tx.get(userDoc.collection('buildings').doc(buildingId)))
              .data()?['level'] as int? ??
          1;
      final nextLvl = lvl + 1;

      // 🔒 Lógica de restricción por Ayuntamiento
      if (nextLvl > 3 && buildingId != 'townhall') {
        final townhallLvl = (await tx
                .get(userDoc.collection('buildings').doc('townhall')))
            .data()?['level'] as int? ?? 1;

        if (nextLvl > townhallLvl) {
          throw Exception('Debes mejorar el Ayuntamiento para subir este edificio.');
        }
      }

      // Costes escalados
      final timeSecs = bType.baseCostTime * nextLvl;
      final woodCost = bType.baseCostWood * nextLvl;
      final stoneCost = bType.baseCostStone * nextLvl;
      final foodCost = bType.baseCostFood * nextLvl;

      final resCol = userDoc.collection('resources');
      final woodDoc = await tx.get(resCol.doc('wood'));
      final stoneDoc = await tx.get(resCol.doc('stone'));
      final foodDoc = await tx.get(resCol.doc('food'));

      final currWood = (woodDoc.data()?['qty'] as int?) ?? 0;
      final currStone = (stoneDoc.data()?['qty'] as int?) ?? 0;
      final currFood = (foodDoc.data()?['qty'] as int?) ?? 0;

      if (currWood < woodCost || currStone < stoneCost || currFood < foodCost) {
        throw Exception('No tienes recursos suficientes.');
      }

      // Restar recursos
      tx.update(resCol.doc('wood'), {'qty': currWood - woodCost});
      tx.update(resCol.doc('stone'), {'qty': currStone - stoneCost});
      tx.update(resCol.doc('food'), {'qty': currFood - foodCost});

      // Programar mejora
      tx.set(
        userDoc.collection('buildings').doc(buildingId),
        {
          'level': lvl, // se mantiene hasta que se complete
          'readyAt': Timestamp.fromMillisecondsSinceEpoch(
            DateTime.now().millisecondsSinceEpoch + timeSecs * 1000,
          ),
        },
      );

      // Guardar meta del target level
      tx.update(userDoc, {
        'meta.upgrading.$buildingId': nextLvl,
      });
    });

    notifyListeners();
    return null; // Éxito, sin errores
  } catch (e) {
    return e.toString().replaceAll('Exception: ', '');
  }
}

Future<void> completeUpgrades(String uid) async {
  final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
  final bColl = userDoc.collection('buildings');
  final now = Timestamp.now();

  final snap = await bColl.where('readyAt', isLessThanOrEqualTo: now).get();
  final userSnapshot = await userDoc.get();
  final meta = userSnapshot.data()?['meta']?['upgrading'] as Map<String, dynamic>? ?? {};

  final resCol = userDoc.collection('resources');
  final batch = FirebaseFirestore.instance.batch();

  for (var d in snap.docs) {
    final bid = d.id;
    final targetLvl = meta[bid] as int?;

    if (targetLvl != null) {
      // ✅ Subir nivel
      batch.update(bColl.doc(bid), {'level': targetLvl, 'readyAt': null});
      batch.update(userDoc, {
        'meta.upgrading.$bid': FieldValue.delete()
      });

      // 🎁 Recompensa si se mejoró el ayuntamiento
      if (bid == 'townhall') {
        final rewardWood = 100 * targetLvl;
        final rewardStone = 60 * targetLvl;
        final rewardFood = 80 * targetLvl;

        batch.update(resCol.doc('wood'), {
          'qty': FieldValue.increment(rewardWood)
        });
        batch.update(resCol.doc('stone'), {
          'qty': FieldValue.increment(rewardStone)
        });
        batch.update(resCol.doc('food'), {
          'qty': FieldValue.increment(rewardFood)
        });
      }
    }
  }

  await batch.commit();
  notifyListeners();
}

// ...

Future<void> collectResources(String uid) async {
  final userDocRef = _userCol.doc(uid);

  // 1) Leemos último collect
  final uSnap = await userDocRef.get();
  final data  = uSnap.data()!;
  final lastTs = (data['meta'] as Map<String, dynamic>?)?['lastCollected']
      as Timestamp?;
  final last = lastTs?.toDate() ?? DateTime.now();

  // 2) Leemos edificios
  final bSnap = await userDocRef.collection('buildings').get();
  int woodGain = 0, stoneGain = 0, foodGain = 0;

  // —— Aquí la única diferencia —— 
  final whIndex = bSnap.docs.indexWhere((d) => d.id == 'warehouse');
  final whLevel = whIndex >= 0
      ? (bSnap.docs[whIndex].data()['level'] as int? ?? 1)
      : 1;
  final warehouseCapacity =
      kBuildingCatalog['warehouse']!.getMaxStorage(whLevel);

  for (var doc in bSnap.docs) {
    final bid   = doc.id;
    final lvl   = (doc.data()['level'] as int?) ?? 1;
    final perHr = kBuildingCatalog[bid]!.prodPerHour;
    if (perHr > 0) {
      final hours = DateTime.now().difference(last).inMinutes / 60.0;
      final gain  = (perHr * lvl * hours).floor();
      switch (bid) {
        case 'lumbermill': woodGain += gain; break;
        case 'stonemine':  stoneGain += gain; break;
        case 'farm':       foodGain  += gain; break;
      }
    }
  }

  // 3) Recursos actuales
  final woodDoc  = await userDocRef.collection('resources').doc('wood').get();
  final stoneDoc = await userDocRef.collection('resources').doc('stone').get();
  final foodDoc  = await userDocRef.collection('resources').doc('food').get();

  final currWood  = (woodDoc.data()?['qty'] as int?) ?? 0;
  final currStone = (stoneDoc.data()?['qty'] as int?) ?? 0;
  final currFood  = (foodDoc.data()?['qty'] as int?) ?? 0;

  // Seguridad: primero ajustamos si ya estaban por encima
  final safeWood  = min(currWood, warehouseCapacity);
  final safeStone = min(currStone, warehouseCapacity);
  final safeFood  = min(currFood, warehouseCapacity);

  // 4) Clamp contra capacidad
  final newWood  = min(safeWood  + woodGain,  warehouseCapacity);
  final newStone = min(safeStone + stoneGain, warehouseCapacity);
  final newFood  = min(safeFood  + foodGain,  warehouseCapacity);

  // 5) Escritura en Firestore
  await FirebaseFirestore.instance.runTransaction((tx) async {
    tx.update(userDocRef, { 'meta.lastCollected': FieldValue.serverTimestamp() });
    tx.set(userDocRef.collection('resources').doc('wood'),
           {'qty': newWood}, SetOptions(merge: true));
    tx.set(userDocRef.collection('resources').doc('stone'),
           {'qty': newStone}, SetOptions(merge: true));
    tx.set(userDocRef.collection('resources').doc('food'),
           {'qty': newFood}, SetOptions(merge: true));
  });

  // 6) Refrescar UI
  _resources = {
    'wood':  newWood,
    'stone': newStone,
    'food':  newFood,
  };
  notifyListeners();
}

/// Obtiene las unidades disponibles para la raza [race]:
/// - Incluye las que tienen requiredRace == null (neutrales)
/// - Y las que tienen requiredRace == race (exclusivas)
List<UnitType> getUnitsForRace(String race) {
  return kUnitCatalog.values
    .where((u) => u.requiredRace == null || u.requiredRace == race)
    .toList();
}


  @override
  void dispose() {
    _bSub?.cancel();
    _rSub?.cancel();
    super.dispose();
  }
}

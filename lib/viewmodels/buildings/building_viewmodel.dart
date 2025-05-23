// lib/viewmodels/building_viewmodel.dart

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:guild/data/building_catalog.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/models/unit_type.dart';
import 'package:guild/services/noti_services.dart';
import 'package:guild/utils/errorcases.dart';

class BuildingViewModel extends ChangeNotifier {
  final _userCol = FirebaseFirestore.instance.collection('users');
final FirebaseFirestore _db = FirebaseFirestore.instance;
 bool _isForeground = true;
  set isForeground(bool v) => _isForeground = v;
  Map<String, int> _levels = {};
  Map<String, DateTime?> _queue = {};
  Map<String, int> _resources = {};

  Map<String, int> get levels => _levels;
  Map<String, DateTime?> get queue => _queue;
  Map<String, int> get resources => _resources;

  StreamSubscription? _bSub;
  StreamSubscription? _rSub;
  int maxConcurrentUpgrades = 2;

    int get pendingUpgradeCount {
    final now = DateTime.now();
    return _queue.values
      .where((dt) => dt != null && dt!.isAfter(now))
      .length;
  }

  /// Indica si podemos arrancar una nueva mejora.
  bool get canStartUpgrade =>
    pendingUpgradeCount < maxConcurrentUpgrades;
void listenData(String uid) {
  // 1️⃣ Cancela suscripciones previas
  _bSub?.cancel();
  _rSub?.cancel();

  // 2️⃣ Copia previa de readyAt para detectar completados
  Map<String, DateTime?> previousReadyAt = Map.from(_queue);

  // 3️⃣ Listener de buildings/{uid}/buildings
  _bSub = _userCol
      .doc(uid)
      .collection('buildings')
      .snapshots()
      .listen((snap) {
    final newLevels = <String, int>{};
    final newQueue = <String, DateTime?>{};
    final now = DateTime.now();

    // Reconstruye niveles y readyAts
    for (var d in snap.docs) {
      final data = d.data();
      newLevels[d.id] = (data['level'] as int?) ?? 1;
      newQueue[d.id] = (data['readyAt'] as Timestamp?)?.toDate();
    }

    // Detecta qué edificios pasaron de pending a done
    for (var entry in previousReadyAt.entries) {
      final bid = entry.key;
      final oldReady = entry.value;
      final newReady = newQueue[bid];

      final wasPending = oldReady != null && oldReady.isAfter(now);
      final nowDone = newReady == null || newReady.isBefore(now);

      if (wasPending && nowDone && !_isForeground) {
        final bType = kBuildingCatalog[bid]!;
        NotificationService.instance.showImmediate(
          id: bid.hashCode + 100000,
          title: 'Mejora completada',
          body: 'Tu ${bType.name} ya está lista.',
          assetPath: bType.assetPath,
        );
      }
    }

    // Actualiza el estado interno y previene duplicados
    _levels = newLevels;
    _queue = newQueue;
    previousReadyAt = Map.from(newQueue);

    notifyListeners();
  });

  // 4️⃣ Listener de recursos
  _rSub = _userCol
      .doc(uid)
      .collection('resources')
      .snapshots()
      .listen((snap) {
    _resources = {
      for (var d in snap.docs) d.id: (d.data()['qty'] as int? ?? 0)
    };
    notifyListeners();
  });
}

/// Recuerda exponer isForeground para que tu MainNavScreen lo actualice:

  void increaseMaxUpgrades(int extra) {
    maxConcurrentUpgrades += extra;
    notifyListeners();
  }
  /// Producción por hora de cada edificio según su nivel
  Map<String, int> get productionPerHour {
    final rates = <String, int>{};
    _levels.forEach((bid, lvl) {
      final b = kBuildingCatalog[bid];
      if (b != null && b.prodPerHour > 0) {
        rates[bid] = b.prodPerHour * lvl;
      }
    });
    return rates;
  }

  /// Tiempos restantes para cada edificio en cola de mejora
  Map<String, Duration> get upgradeTimeLeft {
    final now = DateTime.now();
    return {
      for (final entry in _queue.entries)
        if (entry.value != null && entry.value!.isAfter(now))
          entry.key: entry.value!.difference(now),
    };
  }
/// Dentro de tu BuildingViewModel:

/// Programa la mejora de un edificio y agenda la notificación persistente
Future<String?> upgrade(String uid, String buildingId) async {
  final userDocRef    = _userCol.doc(uid);
  final bldDocRef     = userDocRef.collection('buildings').doc(buildingId);
  final resColRef     = userDocRef.collection('resources');
  final bType         = kBuildingCatalog[buildingId]!;
  final currentLevel  = _levels[buildingId] ?? 1;
  final nextLevel     = currentLevel + 1;
  final timeSecs      = bType.baseCostTime * nextLevel;
  final readyDateTime = DateTime.now().add(Duration(seconds: timeSecs));
  final readyTs       = Timestamp.fromDate(readyDateTime);

  // 0) Límite de mejoras concurrentes
  if (!canStartUpgrade) {
    throw MaxUpgradeReachedException(
      'Solo puedes mejorar hasta $maxConcurrentUpgrades edificios a la vez.'
    );
  }

  // 1) Optimistic UI: dibuja el readyAt inmediatamente
  _queue[buildingId] = readyDateTime;
  notifyListeners();

  try {
    // 2) Transacción: deducir recursos y fijar readyAt en Firestore
    await _db.runTransaction((tx) async {
      final woodSnap  = await tx.get(resColRef.doc('wood'));
      final stoneSnap = await tx.get(resColRef.doc('stone'));
      final foodSnap  = await tx.get(resColRef.doc('food'));

      final currWood  = (woodSnap.data()?['qty']  as int?) ?? 0;
      final currStone = (stoneSnap.data()?['qty'] as int?) ?? 0;
      final currFood  = (foodSnap.data()?['qty']  as int?) ?? 0;

      final woodCost  = bType.baseCostWood  * nextLevel;
      final stoneCost = bType.baseCostStone * nextLevel;
      final foodCost  = bType.baseCostFood  * nextLevel;

      if (currWood < woodCost || currStone < stoneCost || currFood < foodCost) {
        throw InsufficientUpgradeResourcesException(
          'No tienes recursos suficientes para mejorar ${bType.name} a nivel $nextLevel.'
        );
      }

      // Restar recursos
      tx.update(resColRef.doc('wood'),  {'qty': currWood  - woodCost});
      tx.update(resColRef.doc('stone'), {'qty': currStone - stoneCost});
      tx.update(resColRef.doc('food'),  {'qty': currFood  - foodCost});

      // Fijar readyAt
      tx.update(bldDocRef, {
        'readyAt': readyTs,
      });
    });

    // 3) Agenda la notificación persistente (funcionará en background)
    debugPrint('🔔 upgrade: scheduling building noti for $buildingId at $readyDateTime');
    await NotificationService.instance.scheduleBuildingDone(
      id: bldDocRef.id.hashCode,
      buildingName: bType.name,
      finishTime: readyDateTime,
      assetPath: bType.assetPath,
    );
    debugPrint('✅ upgrade: scheduleBuildingDone called for $buildingId');

    // 4) Timer local para actualizar nivel y limpiar readyAt en cliente
    final delay = readyDateTime.difference(DateTime.now());
    Timer(delay, () async {
      debugPrint('⏰ upgrade: timer fired for $buildingId');
      await bldDocRef.update({
        'level': nextLevel,
        'readyAt': null,
      });
      // Actualiza tu estado local
      _levels[buildingId] = nextLevel;
      _queue.remove(buildingId);
      notifyListeners();
    });

    return null;
  } catch (e) {
    // Si algo falla, revertir UI optimista
    _queue.remove(buildingId);
    notifyListeners();
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
        batch.update(bColl.doc(bid), {'level': targetLvl, 'readyAt': null});
        batch.update(userDoc, {
          'meta.upgrading.$bid': FieldValue.delete()
        });

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
/// Cancela la mejora pendiente de [buildingId] y devuelve el 50% de los recursos.
Future<void> cancelUpgrade(String uid, String buildingId) async {
  final userDoc = _userCol.doc(uid);
  final upgDoc  = userDoc.collection('buildingUpgrades').doc(buildingId);
  final bType   = kBuildingCatalog[buildingId]!;

  // Lectura de la mejora pendiente
  final snap = await upgDoc.get();
  if (!snap.exists) return;

  final data      = snap.data()!;
  final targetLvl = data['level'] as int? ?? (_levels[buildingId] ?? 1) + 1;

  // Calculamos el 50% de refund
  final woodCost  = bType.baseCostWood  * targetLvl;
  final stoneCost = bType.baseCostStone * targetLvl;
  final foodCost  = bType.baseCostFood  * targetLvl;

  final refundWood  = (woodCost  * 0.5).floor();
  final refundStone = (stoneCost * 0.5).floor();
  final refundFood  = (foodCost  * 0.5).floor();

  final resCol = userDoc.collection('resources');
  final batch  = FirebaseFirestore.instance.batch();

  // Devolvemos recursos
  batch.update(resCol.doc('wood'),  {'qty': FieldValue.increment(refundWood)});
  batch.update(resCol.doc('stone'), {'qty': FieldValue.increment(refundStone)});
  batch.update(resCol.doc('food'),  {'qty': FieldValue.increment(refundFood)});

  // Borramos la entrada de buildingUpgrades
  batch.delete(upgDoc);

  // Limpiamos meta.upgrading
  batch.update(userDoc, {
    'meta.upgrading.$buildingId': FieldValue.delete(),
  });

  await batch.commit();

  // UI local
  _queue.remove(buildingId);
  notifyListeners();
}

  Future<void> collectResources(String uid) async {
    final userDocRef = _userCol.doc(uid);
    final uSnap = await userDocRef.get();
    final data = uSnap.data()!;
    final lastTs = (data['meta'] as Map<String, dynamic>?)?['lastCollected'] as Timestamp?;
    final last = lastTs?.toDate() ?? DateTime.now();

    final bSnap = await userDocRef.collection('buildings').get();
    int woodGain = 0, stoneGain = 0, foodGain = 0;
    final whIndex = bSnap.docs.indexWhere((d) => d.id == 'warehouse');
    final whLevel = whIndex >= 0 ? (bSnap.docs[whIndex].data()['level'] as int? ?? 1) : 1;
    final warehouseCapacity = kBuildingCatalog['warehouse']!.getMaxStorage(whLevel);

    for (var doc in bSnap.docs) {
      final bid = doc.id;
      final lvl = (doc.data()['level'] as int?) ?? 1;
      final perHr = kBuildingCatalog[bid]!.prodPerHour;
      if (perHr > 0) {
        final hours = DateTime.now().difference(last).inMinutes / 60.0;
        final gain = (perHr * lvl * hours).floor();
        switch (bid) {
          case 'lumbermill': woodGain += gain; break;
          case 'stonemine':  stoneGain += gain; break;
          case 'farm':       foodGain  += gain; break;
        }
      }
    }

    final woodDoc = await userDocRef.collection('resources').doc('wood').get();
    final stoneDoc = await userDocRef.collection('resources').doc('stone').get();
    final foodDoc = await userDocRef.collection('resources').doc('food').get();

    final currWood = (woodDoc.data()?['qty'] as int?) ?? 0;
    final currStone = (stoneDoc.data()?['qty'] as int?) ?? 0;
    final currFood = (foodDoc.data()?['qty'] as int?) ?? 0;

    final safeWood = min(currWood, warehouseCapacity);
    final safeStone = min(currStone, warehouseCapacity);
    final safeFood = min(currFood, warehouseCapacity);

    final newWood  = min(safeWood  + woodGain,  warehouseCapacity);
    final newStone = min(safeStone + stoneGain, warehouseCapacity);
    final newFood  = min(safeFood  + foodGain,  warehouseCapacity);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      tx.update(userDocRef, {'meta.lastCollected': FieldValue.serverTimestamp()});
      tx.set(userDocRef.collection('resources').doc('wood'), {'qty': newWood}, SetOptions(merge: true));
      tx.set(userDocRef.collection('resources').doc('stone'), {'qty': newStone}, SetOptions(merge: true));
      tx.set(userDocRef.collection('resources').doc('food'), {'qty': newFood}, SetOptions(merge: true));
    });

    _resources = {'wood': newWood, 'stone': newStone, 'food': newFood};
    notifyListeners();
  }

  /// Filtra unidades por raza (neutrales o exclusivas)
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

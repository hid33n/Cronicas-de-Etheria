import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:guild/services/noti_services.dart';
import 'package:guild/utils/errorcases.dart';
import '../data/unit_catalog.dart';
import '../models/unit_type.dart';

/// Represents a pending training order
class _QueueItem {
  final String docId;
  final String unitId;
  final int qty;
  final DateTime readyAt;

  _QueueItem({
    required this.docId,
    required this.unitId,
    required this.qty,
    required this.readyAt,
  });
}

class BarracksViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
 bool _isForeground = true;
  set isForeground(bool v) => _isForeground = v;
  // Local state
  final List<_QueueItem> _queue = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _queueSub;

  /// Cola de entrenamiento expuesta a la UI
  List<_QueueItem> get queue => List.unmodifiable(_queue);
  final Map<String, int> _army = {};

  /// Máximo de entrenamientos concurrentes
  int maxConcurrentTraining = 1;

  Map<String, int> get army => _army;

   void initForUser(String uid) {
    // 1️⃣ Listener de la cola de entrenamiento
    _queueSub?.cancel();
    _queueSub = _db
        .collection('users')
        .doc(uid)
        .collection('barracksQueue')
        .snapshots()
        .listen((snap) {
      for (var change in snap.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          // Solo notificar si no estamos en primer plano
          if (!_isForeground) {
            final data = change.doc.data()!;
            final unit = kUnitCatalog[data['unitId']]!;
            final qty = data['qty'] as int;
            NotificationService.instance.showImmediate(
              id: change.doc.id.hashCode,
              title: 'Entrenamiento terminado',
              body: 'Tu ${unit.name} x$qty ya está listo.',
              assetPath: unit.imagePath,
            );
          }
        }
      }

      // Actualizar lista local y refrescar UI
      _queue
        ..clear()
        ..addAll(snap.docs.map((d) {
          final m = d.data();
          return _QueueItem(
            docId: d.id,
            unitId: m['unitId'] as String,
            qty: m['qty'] as int,
            readyAt: (m['readyAt'] as Timestamp).toDate(),
          );
        }));
      notifyListeners();
    }, onError: (e) {
      if (kDebugMode) print('Error escuchando la cola: $e');
    });

    // 2️⃣ Conserva tu listener de ejército (si existía)
    _listenArmy(uid);
  }

  @override
  void dispose() {
    _queueSub?.cancel();
    super.dispose();
  }

  // Listen to user's army field
  void _listenArmy(String uid) {
    _db
        .collection('users').doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data();
      _army
        ..clear()
        ..addAll(
          (data?['army'] as Map<String, dynamic>? ?? {})
              .map((unitId, qty) => MapEntry(unitId, qty as int)),
        );
      notifyListeners();
    });
  }

  /// Cancel a specific training (refunds resources)
  Future<void> cancelTraining(String uid, String docId) async {
    final ref = _db
        .collection('users').doc(uid)
        .collection('barracksQueue')
        .doc(docId);
    final snap = await ref.get();
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return;

    final unitId = data['unitId'] as String;
    final qty = data['qty'] as int? ?? 0;
    final unit = kUnitCatalog[unitId]!;
    final cost = unit.costScaled(qty);

    await _db.runTransaction((tx) async {
      final resCol = _db.collection('users').doc(uid).collection('resources');
      final wRef = resCol.doc('wood');
      final sRef = resCol.doc('stone');
      final fRef = resCol.doc('food');
      final wSnap = await tx.get(wRef);
      final sSnap = await tx.get(sRef);
      final fSnap = await tx.get(fRef);
      final wCurr = (wSnap.data()?['qty'] as int?) ?? 0;
      final sCurr = (sSnap.data()?['qty'] as int?) ?? 0;
      final fCurr = (fSnap.data()?['qty'] as int?) ?? 0;
      tx.update(wRef, {'qty': wCurr + cost.wood});
      tx.update(sRef, {'qty': sCurr + cost.stone});
      tx.update(fRef, {'qty': fCurr + cost.food});
      tx.delete(ref);
    });

    // Actualizar cola local inmediatamente
    _queue.removeWhere((item) => item.docId == docId);
    notifyListeners();
  }

/// Enqueue training, deducting resources
Future<void> trainUnit(String uid, String unitId, int qty) async {
  // 1) Límite concurrente
  if (_queue.length >= maxConcurrentTraining) {
    throw MaxTrainingReachedException(
      'Límite de entrenamientos alcanzado (${_queue.length}/$maxConcurrentTraining).'
    );
  }

  // 2) Recursos y readyAt
  final unit = kUnitCatalog[unitId]!;
  final cost = unit.costScaled(qty);
  final resCol = _db.collection('users').doc(uid).collection('resources');
  final resources = await _getCurrentResources(resCol);
  if (!resources.hasEnough(cost)) {
    throw InsufficientResourcesException(
      'No tienes suficientes recursos para entrenar ${unit.name} x$qty.'
    );
  }
  final readyAt = DateTime.now().add(
    Duration(seconds: unit.baseTrainSecs * qty)
  );

  // 3) Transacción: deducir recursos y crear la orden
  final queueRef = _db
      .collection('users')
      .doc(uid)
      .collection('barracksQueue')
      .doc();
  await _db.runTransaction((tx) async {
    _deductResources(tx, resCol, resources, cost);
    tx.set(queueRef, {
      'unitId': unitId,
      'qty': qty,
      'readyAt': Timestamp.fromDate(readyAt),
    });
  });

  // 4) Agenda + persiste la notificación (resistente a cierre de app)
  try {
    await NotificationService.instance.scheduleTrainingDone(
      id: queueRef.id.hashCode,
      title: 'Entrenamiento completado',
      body: 'Tu ${unit.name} x$qty está listo.',
      finishTime: readyAt,
      assetPath: unit.imagePath,
    );
  } catch (e) {
    debugPrint('Error programando noti: $e');
  }

  // 5) Timer local para procesar el fin del entrenamiento
  final delay = readyAt.difference(DateTime.now());
  Timer(delay, () async {
    // 5.1) Borra la orden de la cola
    try {
      await _db
        .collection('users').doc(uid)
        .collection('barracksQueue')
        .doc(queueRef.id)
        .delete();
    } catch (e) {
      debugPrint('Error eliminando orden tras timer: $e');
    }

    // 5.2) Incrementa el army en Firestore
    try {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(uid);
        final snap    = await tx.get(userRef);
        final data    = snap.data() as Map<String, dynamic>? ?? {};
        final armyMap = Map<String, dynamic>.from(data['army'] ?? {});
        final prev    = (armyMap[unitId] as int?) ?? 0;
        armyMap[unitId] = prev + qty;
        tx.update(userRef, {'army': armyMap});
      });
    } catch (e) {
      debugPrint('Error actualizando army tras timer: $e');
    }

    // 5.3) Actualiza la UI local
    _queue.removeWhere((item) => item.docId == queueRef.id);
    _army[unitId] = (_army[unitId] ?? 0) + qty;
    notifyListeners();
  });

  // 6) Añade la nueva orden a la cola local
  final newItem = _QueueItem(
    docId: queueRef.id,
    unitId: unitId,
    qty: qty,
    readyAt: readyAt,
  );
  if (_queue.every((item) => item.docId != newItem.docId)) {
    _queue.add(newItem);
    notifyListeners();
  }
}






  /// Complete trainings and add to user's army field
  Future<void> completeTrainings(String uid) async {
    final now = DateTime.now();
    final readyDocs = await _db
        .collection('users').doc(uid)
        .collection('barracksQueue')
        .where('readyAt', isLessThanOrEqualTo: now)
        .get();

    final batch = _db.batch();

    for (var doc in readyDocs.docs) {
      final data = doc.data();
      final unitId = data['unitId'] as String;
      final qty = data['qty'] as int? ?? 0;
      final userRef = _db.collection('users').doc(uid);
      batch.update(userRef, {'army.$unitId': FieldValue.increment(qty)});
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// Para cuando el usuario compre un slot extra
  void increaseMaxTraining(int extra) {
    maxConcurrentTraining += extra;
    notifyListeners();
  }
  /// Read current resources
  Future<_Resources> _getCurrentResources(CollectionReference col) async {
    final wSnap = await col.doc('wood').get();
    final sSnap = await col.doc('stone').get();
    final fSnap = await col.doc('food').get();
    final wData = wSnap.data() as Map<String, dynamic>?;
    final sData = sSnap.data() as Map<String, dynamic>?;
    final fData = fSnap.data() as Map<String, dynamic>?;
    final w = (wData?['qty'] as int?) ?? 0;
    final s = (sData?['qty'] as int?) ?? 0;
    final f = (fData?['qty'] as int?) ?? 0;
    return _Resources(wood: w, stone: s, food: f);
  }

  void _deductResources(Transaction tx, CollectionReference col,
      _Resources cur, _Resources cost) {
    tx.update(col.doc('wood'), {'qty': cur.wood - cost.wood});
    tx.update(col.doc('stone'), {'qty': cur.stone - cost.stone});
    tx.update(col.doc('food'), {'qty': cur.food - cost.food});
  }
}

class _Resources {
  final int wood;
  final int stone;
  final int food;
  _Resources({required this.wood, required this.stone, required this.food});
  bool hasEnough(_Resources o) => wood >= o.wood && stone >= o.stone && food >= o.food;
}

extension on UnitType {
  _Resources costScaled(int qty) => _Resources(
    wood: costWood * qty,
    stone: costStone * qty,
    food: costFood * qty,
  );
}

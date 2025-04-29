import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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

  // Local state
  final List<_QueueItem> _queue = [];
  final Map<String, int> _army = {};

  /// Máximo de entrenamientos concurrentes
  int maxConcurrentTraining = 1;

  List<_QueueItem> get queue => List.unmodifiable(_queue);
  Map<String, int> get army => _army;

  /// Initialize listeners for this user
  void initForUser(String uid) {
    _listenQueue(uid);
    _listenArmy(uid);
  }

  // Listen to pending training queue
  void _listenQueue(String uid) {
    _db
        .collection('users').doc(uid)
        .collection('barracksQueue')
        .snapshots()
        .listen((snap) {
      _queue
        ..clear()
        ..addAll(snap.docs.map((d) {
          final data = d.data() as Map<String, dynamic>?;
          return _QueueItem(
            docId: d.id,
            unitId: data?['unitId'] as String,
            qty: data?['qty'] as int? ?? 0,
            readyAt: (data?['readyAt'] as Timestamp).toDate(),
          );
        }));
      notifyListeners();
    });
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
    // 1) Verificar límite concurrente
    if (_queue.length >= maxConcurrentTraining) {
      throw Exception(
        'Límite de entrenamientos alcanzado ' 
        '(${_queue.length}/$maxConcurrentTraining).'
      );
    }

    final unit = kUnitCatalog[unitId]!;
    final cost = unit.costScaled(qty);
    final resCol = _db.collection('users').doc(uid).collection('resources');

    final resources = await _getCurrentResources(resCol);
    if (!resources.hasEnough(cost)) {
      throw Exception('Recursos insuficientes');
    }

    final readyAt = DateTime.now().add(
      Duration(seconds: unit.baseTrainSecs * qty)
    );

    // 2) Transacción: deducir y crear doc en Firestore
    final queueRef = _db
        .collection('users').doc(uid)
        .collection('barracksQueue')
        .doc();

    await _db.runTransaction((tx) async {
      _deductResources(tx, resCol, resources, cost);
      tx.set(queueRef, {
        'unitId': unitId,
        'qty': qty,
        'readyAt': readyAt,
      });
    });

    // 3) Actualizar cola local inmediatamente
    _queue.add(_QueueItem(
      docId: queueRef.id,
      unitId: unitId,
      qty: qty,
      readyAt: readyAt,
    ));
    notifyListeners();
  }

  /// Para cuando el usuario compre un slot extra
  void increaseMaxTraining(int extra) {
    maxConcurrentTraining += extra;
    notifyListeners();
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

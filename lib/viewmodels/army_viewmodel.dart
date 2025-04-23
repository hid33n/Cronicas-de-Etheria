import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ArmyViewModel extends ChangeNotifier {
  final _armyColRoot =
      FirebaseFirestore.instance.collection('army'); // root

  Map<String, int> _army = {}; // unitId → qty
  Map<String, int> get army => _army;

  /// Escucha en tiempo real el ejército del usuario
  void listenArmy(String uid) {
    _armyColRoot.doc(uid).collection('units').snapshots().listen((snap) {
      _army = {
        for (var d in snap.docs) d.id: (d.data()['qty'] as int?) ?? 0,
      };
      notifyListeners();
    });
  }

  /// Devuelve la cantidad poseída de una unidad
  int qtyOf(String unitId) => _army[unitId] ?? 0;
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/unit_catalog.dart';

class DuelResult {
  final String winnerUid;
  final String log;
  DuelResult(this.winnerUid, this.log);
}

class DuelViewModel extends ChangeNotifier {
  final _duelCol = FirebaseFirestore.instance.collection('duels');

  /// Crea un reto
  Future<String> challenge(String challenger, String challenged) async {
    final doc = await _duelCol.add({
      'challenger': challenger,
      'challenged': challenged,
      'status': 'pending',
      'createdAt': DateTime.now(),
    });
    return doc.id;
  }

  /// Acepta y resuelve un duelo
  Future<DuelResult> acceptAndResolve({
    required String duelId,
    required Map<String, int> atkArmy,
    required Map<String, int> defArmy,
  }) async {
    final res = _resolveBattle(atkArmy, defArmy);
    await _duelCol.doc(duelId).update({
      'status': 'finished',
      'result': {'winner': res.winnerUid, 'log': res.log},
      'finishedAt': DateTime.now(),
    });
    return res;
  }

  // Algoritmo simplificado
  DuelResult _resolveBattle(
      Map<String, int> atk, Map<String, int> def) {
    int hpA = 0, hpB = 0, dmgA = 0, dmgB = 0;
    atk.forEach((u, q) {
      hpA += kUnitCatalog[u]!.hp * q;
      dmgA += kUnitCatalog[u]!.atk * q;
    });
    def.forEach((u, q) {
      hpB += kUnitCatalog[u]!.hp * q;
      dmgB += kUnitCatalog[u]!.atk * q;
    });
    final rand = Random();
    dmgA = (dmgA * (0.9 + rand.nextDouble() * 0.2)).round();
    dmgB = (dmgB * (0.9 + rand.nextDouble() * 0.2)).round();

    final turnsKillB = (hpB / dmgA).ceil();
    final turnsKillA = (hpA / dmgB).ceil();

    final winner = turnsKillB <= turnsKillA ? 'attacker' : 'defender';
    final log = 'Atk‑HP:$hpA Dmg:$dmgA  |  Def‑HP:$hpB Dmg:$dmgB  →  gana $winner';
    return DuelResult(winner, log);
  }
}

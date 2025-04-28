import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/unit_catalog.dart';

typedef Army = Map<String,int>;

/// Resultado de una batalla PvP
class BattleResult {
  final String attackerId;
  final String defenderId;
  final bool attackerWon;
  final Army survivorsAttacker;
  final Army survivorsDefender;
  final Army lossesAttacker;
  final Army lossesDefender;
  final int goldReward;
  final int eloDelta;

  BattleResult({
    required this.attackerId,
    required this.defenderId,
    required this.attackerWon,
    required this.survivorsAttacker,
    required this.survivorsDefender,
    required this.lossesAttacker,
    required this.lossesDefender,
    required this.goldReward,
    required this.eloDelta,
  });
}

/// Estructura interna de simulación
class _SimResult {
  final bool attackerWon;
  final Army survivorsAttacker;
  final Army survivorsDefender;
  final int goldReward;

  _SimResult({
    required this.attackerWon,
    required this.survivorsAttacker,
    required this.survivorsDefender,
    required this.goldReward,
  });
}

class BattleViewModel extends ChangeNotifier {
  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final Random _rng = Random();
  static const int _kFactor = 32;

  /// Inicia una batalla PvP usando [attackerArmyOverride] o el army del usuario.
  Future<BattleResult> randomBattle(
    String userId, {
    Army? attackerArmyOverride,
  }) async {
    // 1) Elo atacante
    final meSnap = await _fs.collection('users').doc(userId).get();
    final myElo = (meSnap.data()?['eloRating'] as int?) ?? 1000;

    // 2) Buscar oponentes Elo ±100
    final q = await _fs
        .collection('users')
        .where('eloRating', isGreaterThan: myElo - 100)
        .where('eloRating', isLessThan: myElo + 100)
        .limit(20)
        .get();
    final candidateIds = q.docs
        .map((d) => d.id)
        .where((id) => id != userId)
        .toList();
    if (candidateIds.isEmpty) {
      throw Exception('No se encontró oponente con Elo cercano.');
    }
    candidateIds.shuffle(_rng);

    // 3) Seleccionar el primer oponente con unidades
    String? oppId;
    for (final id in candidateIds) {
      final army = await _loadArmy(id);
      final total = army.values.fold<int>(0, (a, b) => a + b);
      if (total > 0) {
        oppId = id;
        break;
      }
    }
    if (oppId == null) {
      throw Exception('No se encontró oponente con unidades entrenadas.');
    }

    // 4) Cargar army atacante
    final myArmy = <String,int>{};
    if (attackerArmyOverride != null && attackerArmyOverride.isNotEmpty) {
      myArmy.addAll(attackerArmyOverride);
    } else {
      myArmy.addAll(await _loadArmy(userId));
    }

    // 5) Cargar army defensor
    final opArmy = await _loadArmy(oppId);

    // 6) Simular combate
    final sim = _simulateBattle(
      attackerId: userId,
      defenderId: oppId,
      atkArmy: myArmy,
      defArmy: opArmy,
    );

    // 7) Calcular pérdidas
    final lossesAtt = <String,int>{};
    myArmy.forEach((unitId, qty) {
      lossesAtt[unitId] = qty - (sim.survivorsAttacker[unitId] ?? 0);
    });
    final lossesDef = <String,int>{};
    opArmy.forEach((unitId, qty) {
      lossesDef[unitId] = qty - (sim.survivorsDefender[unitId] ?? 0);
    });

    // 8) Guardar supervivientes en user.army
    await _applySurvivors(userId, sim.survivorsAttacker);
    await _applySurvivors(oppId, sim.survivorsDefender);

    // 9) Otorgar oro al ganador
    if (sim.attackerWon) {
      await _fs.collection('users').doc(userId)
        .update({'gold': FieldValue.increment(sim.goldReward)});
    }

    // 10) Actualizar Elo
    final eloDelta = await _updateEloRatings(
      attackerId:  userId,
      defenderId:  oppId,
      attackerWon: sim.attackerWon,
      previousElo: myElo,
    );

    return BattleResult(
      attackerId: userId,
      defenderId: oppId,
      attackerWon: sim.attackerWon,
      survivorsAttacker: sim.survivorsAttacker,
      survivorsDefender: sim.survivorsDefender,
      lossesAttacker: lossesAtt,
      lossesDefender: lossesDef,
      goldReward: sim.goldReward,
      eloDelta: eloDelta,
    );
  }

  /// Carga el campo 'army' de users/{uid}
  Future<Army> _loadArmy(String uid) async {
    final snap = await _fs.collection('users').doc(uid).get();
    final data = snap.data()?['army'] as Map<String, dynamic>?;
    if (data == null) return {};
    return data.map((k, v) => MapEntry(k, v as int));
  }
/// Obtiene el ejército disponible del usuario desde Firestore
Future<Map<String,int>> fetchAvailableUnits(String uid) async {
  final doc = await _fs.collection('users').doc(uid).get();
  final data = doc.data()?['army'] as Map<String,dynamic>? ?? {};
  final avail = <String,int>{};
  data.forEach((unitId, qty) {
    final amount = qty as int;
    if (amount > 0 && kUnitCatalog.containsKey(unitId)) {
      avail[unitId] = amount;
    }
  });
  return avail;
}
  /// Simula el combate y devuelve resultado
  _SimResult _simulateBattle({
    required String attackerId,
    required String defenderId,
    required Army atkArmy,
    required Army defArmy,
  }) {
    double strength(Map<String,int> army) => army.entries.fold(0.0, (sum, e) {
      final unit = kUnitCatalog[e.key]!;
      return sum + e.value * unit.hp * unit.atk;
    });

    final fa = strength(atkArmy);
    final fd = strength(defArmy);
    final pWin = (fa + fd) > 0 ? fa / (fa + fd) : 0.5;
    final attackerWon = _rng.nextDouble() < pWin;

    final survA = ((attackerWon ? pWin : (1 - pWin))).clamp(0.0, 1.0);
    final survB = ((attackerWon ? (1 - pWin) : pWin)).clamp(0.0, 1.0);

    Map<String,int> calcSurv(Map<String,int> army, double pct) =>
      army.map((id, qty) => MapEntry(id, (qty * pct).floor()));

    final survAtt = calcSurv(atkArmy, survA);
    final survDef = calcSurv(defArmy, survB);
    final goldReward = ((fa + fd) * 0.001).floor().clamp(10, 500);

    return _SimResult(
      attackerWon: attackerWon,
      survivorsAttacker: survAtt,
      survivorsDefender: survDef,
      goldReward: goldReward,
    );
  }

  /// Aplica supervivientes actualizando user.army
  Future<void> _applySurvivors(String uid, Army survivors) async {
    final userRef = _fs.collection('users').doc(uid);
    final updates = <String, dynamic>{};
    survivors.forEach((unitId, qty) {
      updates['army.$unitId'] = qty;
    });
    await userRef.update(updates);
  }

  /// Actualiza Elo y retorna delta
  Future<int> _updateEloRatings({
    required String attackerId,
    required String defenderId,
    required bool attackerWon,
    required int previousElo,
  }) async {
    final aDoc = await _fs.collection('users').doc(attackerId).get();
    final dDoc = await _fs.collection('users').doc(defenderId).get();
    final rA = (aDoc.data()?['eloRating'] as int?) ?? 1000;
    final rB = (dDoc.data()?['eloRating'] as int?) ?? 1000;

    final eA = 1 / (1 + pow(10, (rB - rA) / 400));
    final eB = 1 / (1 + pow(10, (rA - rB) / 400));
    final sA = attackerWon ? 1 : 0;
    final sB = 1 - sA;

    final newA = (rA + _kFactor * (sA - eA)).round();
    final newB = (rB + _kFactor * (sB - eB)).round();

    await _fs.collection('users').doc(attackerId).update({'eloRating': newA});
    await _fs.collection('users').doc(defenderId).update({'eloRating': newB});

    return newA - previousElo;
  }
}

// File: lib/viewmodels/battle_viewmodel.dart

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../data/unit_catalog.dart';
import '../models/battle_report_model.dart';

typedef Army = Map<String, int>;

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

 Future<BattleResult> randomBattle(
  String userId, {
  Army? attackerArmyOverride,
}) async {
  try {
    // 1) Obtener Elo atacante
    final meSnap = await _fs.collection('users').doc(userId).get();
    final myElo = (meSnap.data()?['eloRating'] as int?) ?? 1000;

    // 2) Matchmaking elástico
    String? oppId;
    int delta = 50;           // Empieza ±50
    const int maxDelta = 800; // Tope ±800
    while (delta <= maxDelta && oppId == null) {
      // 2a) Buscar candidatos en rango [myElo - delta, myElo + delta]
      final q = await _fs
          .collection('users')
          .where('eloRating', isGreaterThan: myElo - delta)
          .where('eloRating', isLessThan: myElo + delta)
          .limit(20)
          .get();

      // 2b) Filtrar self y barajar
      final candidates = q.docs
          .map((d) => d.id)
          .where((id) => id != userId)
          .toList()
        ..shuffle(_rng);

      // 2c) Elegir el primero con ejército
      for (final id in candidates) {
        final army = await _loadArmy(id);
        if (army.values.any((qty) => qty > 0)) {
          oppId = id;
          break;
        }
      }

      // 2d) Si no lo encontró, duplicar delta y repetir
      delta *= 2;
    }

    // 2e) Si tras maxDelta sigue null, lanzamos excepción (o aquí podrías caer a NPC)
    if (oppId == null) {
      throw Exception('No se encontró oponente con tropas dentro de Elo ±$maxDelta.');
    }

    // 3) Cargar ejércitos
    final myArmy = <String,int>{};
    if (attackerArmyOverride != null && attackerArmyOverride.isNotEmpty) {
      myArmy.addAll(attackerArmyOverride);
    } else {
      myArmy.addAll(await _loadArmy(userId));
    }
    final opArmy = await _loadArmy(oppId);

    // 4) Simular combate
    final sim = _simulateBattleAdvanced(atkArmy: myArmy, defArmy: opArmy);

    // 5) Calcular pérdidas
    final lossesAtt = <String,int>{};
    myArmy.forEach((unit, qty) {
      lossesAtt[unit] = qty - (sim.survivorsAttacker[unit] ?? 0);
    });
    final lossesDef = <String,int>{};
    opArmy.forEach((unit, qty) {
      lossesDef[unit] = qty - (sim.survivorsDefender[unit] ?? 0);
    });

    // 6) Persistir supervivientes
    await _applySurvivors(userId, sim.survivorsAttacker);
    await _applySurvivors(oppId, sim.survivorsDefender);

    // 7) Recompensa de oro
    if (sim.attackerWon) {
      await _fs.collection('users').doc(userId)
        .update({'gold': FieldValue.increment(sim.goldReward)});
    }

    // 8) Actualizar Elo
    final eloDelta = await _updateEloRatings(
      attackerId:  userId,
      defenderId:  oppId,
      attackerWon: sim.attackerWon,
      previousElo: myElo,
    );

    // 9) Armar y guardar resultado
    final result = BattleResult(
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
    await _saveBattleReport(result);

    return result;
  } catch (e, st) {
    debugPrint('Error in randomBattle: $e');
    debugPrint('Stack trace:\n$st');
    rethrow;
  }
}


  Future<Army> _loadArmy(String uid) async {
    try {
      final snap = await _fs.collection('users').doc(uid).get();
      final data = snap.data()?['army'] as Map<String, dynamic>?;
      return data?.map((k, v) => MapEntry(k, v as int)) ?? {};
    } catch (e) {
      debugPrint('Error loading army for $uid: $e');
      return {};
    }
  }

  Future<Map<String, int>> fetchAvailableUnits(String uid) async {
    try {
      final data = (await _fs.collection('users').doc(uid).get()).data()?['army'] as Map<String, dynamic>?;
      final avail = <String, int>{};
      data?.forEach((unit, qty) {
        final amount = qty as int;
        if (amount > 0 && kUnitCatalog.containsKey(unit)) {
          avail[unit] = amount;
        }
      });
      return avail;
    } catch (e) {
      debugPrint('Error in fetchAvailableUnits: $e');
      return {};
    }
  }

  /// Simulación de combate complejo con validación de claves
  /// Reemplaza tu _simulateBattleComplex por este método:
_SimResult _simulateBattleAdvanced({
  required Army atkArmy,
  required Army defArmy,
}) {
  // 1) Calculamos stats base
  double attackPower = atkArmy.entries.fold<double>(0.0, (sum, e) {
    final unit = kUnitCatalog[e.key];
    if (unit == null) return sum;
    return sum + e.value * unit.atk;
  });
  double defensePower = defArmy.entries.fold<double>(0.0, (sum, e) {
    final unit = kUnitCatalog[e.key];
    if (unit == null) return sum;
    return sum + e.value * unit.def;
  });
  double totalHPAtt = atkArmy.entries.fold<double>(0.0, (sum, e) {
    final unit = kUnitCatalog[e.key];
    if (unit == null) return sum;
    return sum + e.value * unit.hp;
  });
  double totalHPDef = defArmy.entries.fold<double>(0.0, (sum, e) {
    final unit = kUnitCatalog[e.key];
    if (unit == null) return sum;
    return sum + e.value * unit.hp;
  });

  // 2) Iteramos rondas hasta que uno quede con poca HP
  double remainingHPAtt = totalHPAtt;
  double remainingHPDef = totalHPDef;
  const int maxRounds = 10;
  int round = 0;
  while (round < maxRounds && remainingHPAtt > 0 && remainingHPDef > 0) {
    round++;
    // 2a) Daño aleatorio de atacante
    final randAtk = attackPower * (0.8 + _rng.nextDouble() * 0.4);
    // 2b) Mitigación por defensa del defensor
    final mitigDef = defensePower * 0.3;
    final dmgToDef = (randAtk - mitigDef).clamp(0.0, randAtk);

    // 2c) Daño aleatorio del defensor
    final randDef = defensePower * (0.8 + _rng.nextDouble() * 0.4);
    final mitigAtt = attackPower * 0.2;
    final dmgToAtt = (randDef - mitigAtt).clamp(0.0, randDef);

    remainingHPDef = (remainingHPDef - dmgToDef).clamp(0.0, totalHPDef);
    remainingHPAtt = (remainingHPAtt - dmgToAtt).clamp(0.0, totalHPAtt);

    // Opcional: Reducir ligeramente el poder tras cada ronda
    attackPower *= 0.95;
    defensePower *= 0.95;
  }

  // 3) Relacionamos HP restante a unidades supervivientes
  Map<String, int> survivorsOf(Army army, double totalHP, double remHP) {
    if (totalHP <= 0) return { for (var e in army.entries) e.key: 0 };
    final ratio = (remHP / totalHP).clamp(0.0, 1.0);
    return army.map((id, qty) => MapEntry(id, (qty * ratio).floor()));
  }

  final survAtt = survivorsOf(atkArmy, totalHPAtt, remainingHPAtt);
  final survDef = survivorsOf(defArmy, totalHPDef, remainingHPDef);

  // 4) Determinamos ganador
  final attackerWon = remainingHPAtt >= remainingHPDef;

  // 5) Premio de oro
  final goldReward = ((totalHPAtt + totalHPDef) * 0.001).floor().clamp(10, 1000);

  return _SimResult(
    attackerWon: attackerWon,
    survivorsAttacker: survAtt,
    survivorsDefender: survDef,
    goldReward: goldReward,
  );
}


  Future<void> _saveBattleReport(BattleResult res) async {
    final data = {
      'attackerId': res.attackerId,
      'defenderId': res.defenderId,
      'attackerWon': res.attackerWon,
      'goldReward': res.goldReward,
      'eloDeltaAttacker': res.eloDelta,
      'eloDeltaDefender': -res.eloDelta,
      'survivorsAttacker': res.survivorsAttacker,
      'survivorsDefender': res.survivorsDefender,
      'lossesAttacker': res.lossesAttacker,
      'lossesDefender': res.lossesDefender,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final attackerRef = _fs
        .collection('users')
        .doc(res.attackerId)
        .collection('battleReports')
        .doc();
    final defenderRef = _fs
        .collection('users')
        .doc(res.defenderId)
        .collection('battleReports')
        .doc(attackerRef.id);

    final batch = _fs.batch();
    batch.set(attackerRef, data);
    batch.set(defenderRef, data);
    await batch.commit();
  }

  Future<void> _applySurvivors(String uid, Army survivors) async {
    try {
      final ref = _fs.collection('users').doc(uid);
      final updates = <String, dynamic>{};
      for (var e in survivors.entries) {
        updates['army.${e.key}'] = e.value;
      }
      await ref.update(updates);
    } catch (e) {
      debugPrint('Error in _applySurvivors for $uid: $e');
      rethrow;
    }
  }

  Future<int> _updateEloRatings({
    required String attackerId,
    required String defenderId,
    required bool attackerWon,
    required int previousElo,
  }) async {
    try {
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
    } catch (e) {
      debugPrint('Error in _updateEloRatings: $e');
      rethrow;
    }
  }
}

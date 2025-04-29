// lib/models/battle_report_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
typedef Army = Map<String, int>;

class BattleReport {
  final String id;
  final String attackerId;
  final String defenderId;
  final bool attackerWon;
  final Army survivorsAttacker;
  final Army survivorsDefender;
  final Army lossesAttacker;
  final Army lossesDefender;
  final int goldReward;
  final int eloDeltaAttacker;
  final int eloDeltaDefender;
  final DateTime timestamp;

  BattleReport({
    required this.id,
    required this.attackerId,
    required this.defenderId,
    required this.attackerWon,
    required this.survivorsAttacker,
    required this.survivorsDefender,
    required this.lossesAttacker,
    required this.lossesDefender,
    required this.goldReward,
    required this.eloDeltaAttacker,
    required this.eloDeltaDefender,
    required this.timestamp,
  });

  factory BattleReport.fromDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    // Safely parse timestamp, con fallback a DateTime.now()
    final ts = data['timestamp'];
    final dt = ts is Timestamp ? ts.toDate() : DateTime.now();

    return BattleReport(
      id: doc.id,
      attackerId: data['attackerId'] as String? ?? '',
      defenderId: data['defenderId'] as String? ?? '',
      attackerWon: data['attackerWon'] as bool? ?? false,
      survivorsAttacker:
          Map<String, int>.from(data['survivorsAttacker'] as Map? ?? {}),
      survivorsDefender:
          Map<String, int>.from(data['survivorsDefender'] as Map? ?? {}),
      lossesAttacker:
          Map<String, int>.from(data['lossesAttacker'] as Map? ?? {}),
      lossesDefender:
          Map<String, int>.from(data['lossesDefender'] as Map? ?? {}),
      goldReward: data['goldReward'] as int? ?? 0,
      eloDeltaAttacker: data['eloDeltaAttacker'] as int? ?? 0,
      eloDeltaDefender: data['eloDeltaDefender'] as int? ?? 0,
      timestamp: dt,
    );
  }
}

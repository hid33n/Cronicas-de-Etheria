import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart';
import 'package:guild/viewmodels/battle_viewmodel.dart';
import 'package:provider/provider.dart';

class PvpDialog extends StatefulWidget {
  const PvpDialog({Key? key}) : super(key: key);

  @override
  _PvpDialogState createState() => _PvpDialogState();
}

class _PvpDialogState extends State<PvpDialog> {
  bool _isLoading = true;
  Map<String, int> _available = {};
  Map<String, int> _selected = {};

  @override
  void initState() {
    super.initState();
    _loadArmy();
  }

  Future<void> _loadArmy() async {
    try {
      final uid = context.read<AuthViewModel>().user!.id;
      final docs = await FirebaseFirestore.instance
          .collection('army')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: '${uid}_')
          .where(FieldPath.documentId, isLessThanOrEqualTo: '${uid}_\uf8ff')
          .get();

      final avail = <String, int>{};
      for (var d in docs.docs) {
        final map = d.data() as Map<String, dynamic>?;
        final qty = (map?['qty'] as int?) ?? 0;
        final unitId = d.id.split('_').last;
        if (qty > 0) {
          avail[unitId] = qty;
          _selected[unitId] = 0;
        }
      }
      setState(() {
        _available = avail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar unidades: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Duelo PvP', style: TextStyle(color: Colors.amber)),
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _available.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes unidades entrenadas',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _available.entries.map((e) {
                      final unitType = kUnitCatalog[e.key]!;
                      final max = e.value;
                      final sel = _selected[e.key]!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Text(unitType.emoji, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                unitType.name,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.white70),
                              onPressed: sel > 0
                                  ? () => setState(() => _selected[e.key] = sel - 1)
                                  : null,
                            ),
                            Text('$sel', style: const TextStyle(color: Colors.white70)),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.white70),
                              onPressed: sel < max
                                  ? () => setState(() => _selected[e.key] = sel + 1)
                                  : null,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: _selected.values.every((v) => v == 0)
              ? null
              : () {
                  // Capturar referencias antes de cerrar diálogo
                  final uid = context.read<AuthViewModel>().user!.id;
                  final vm = context.read<BattleViewModel>();
                  final messenger = ScaffoldMessenger.of(context);
                  final selectedArmy = Map<String, int>.from(_selected)
                    ..removeWhere((_, cnt) => cnt == 0);

                  Navigator.pop(context);

                  messenger.showSnackBar(
                    SnackBar(
                      content: const Text('Tus unidades salieron en busca de un enemigo'),
                      backgroundColor: Colors.blueGrey[800],
                      behavior: SnackBarBehavior.floating,
                    ),
                  );

                  // Ejecutar batalla inmediatamente
                  vm.randomBattle(
                    uid,
                    attackerArmyOverride: selectedArmy,
                  ).then((result) async {
                    try {
                      final fs = FirebaseFirestore.instance;
                      final reportData = {
                        'timestamp': FieldValue.serverTimestamp(),
                        'opponentId': result.defenderId,
                        'attackerWon': result.attackerWon,
                        'survivorsAttacker': result.survivorsAttacker,
                        'survivorsDefender': result.survivorsDefender,
                        'lossesAttacker': result.lossesAttacker,
                        'lossesDefender': result.lossesDefender,
                        'goldReward': result.goldReward,
                        'eloDelta': result.eloDelta,
                      };
                      await fs
                          .collection('users')
                          .doc(uid)
                          .collection('pvp_reports')
                          .add(reportData);
                      await fs
                          .collection('users')
                          .doc(result.defenderId)
                          .collection('pvp_reports')
                          .add({
                        ...reportData,
                        'opponentId': uid,
                        'attackerWon': !result.attackerWon,
                      });

                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('📜 Informe PvP listo'),
                          backgroundColor: Colors.green[800],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (e) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Error guardando informe: $e'),
                          backgroundColor: Colors.red[700],
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }).catchError((e) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error en PvP: $e'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  });
                },
          child: const Text('¡Vamos!', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }
}

// lib/screens/pvp/pvp_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/models/unit_type.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:guild/viewmodels/battle_viewmodel.dart';

class PvpDialog extends StatefulWidget {
  const PvpDialog({Key? key}) : super(key: key);

  @override
  _PvpDialogState createState() => _PvpDialogState();
}

class _PvpDialogState extends State<PvpDialog> {
  late final Future<Map<String, int>> _armyFuture;
  final Map<String, int> _selected = {};
  late List<String> _unitIds;

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user!.id;
    _armyFuture = context.read<BattleViewModel>().fetchAvailableUnits(uid);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text('Duelo PvP', style: TextStyle(color: Colors.amber)),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: FutureBuilder<Map<String, int>>(
          future: _armyFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar ejército',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }
            final avail = snapshot.data!;
            if (avail.isEmpty) {
              return const Center(
                child: Text('No tienes unidades entrenadas', style: TextStyle(color: Colors.white70)),
              );
            }
            _unitIds = avail.keys.toList();
            for (final id in _unitIds) {
              _selected.putIfAbsent(id, () => 0);
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _unitIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final unitId = _unitIds[i];
                final maxQty = avail[unitId]!;
                final selQty = _selected[unitId]!;
                final unitType = kUnitCatalog[unitId]!;

                return PvpUnitRow(
                  unit: unitType,
                  maxQty: maxQty,
                  selQty: selQty,
                  onIncrement: selQty < maxQty
                      ? () => setState(() => _selected[unitId] = selQty + 1)
                      : null,
                  onDecrement: selQty > 0
                      ? () => setState(() => _selected[unitId] = selQty - 1)
                      : null,
                );
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: _selected.values.any((qty) => qty > 0) ? _startBattle : null,
          child: const Text('¡Vamos!', style: TextStyle(color: Colors.black87)),
        ),
      ],
    );
  }

  void _startBattle() {
    final uid = context.read<AuthViewModel>().user!.id;
    final battleVm = context.read<BattleViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final selectedArmy = Map<String, int>.from(_selected)
      ..removeWhere((_, val) => val == 0);

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Tus unidades salen al combate…'),
        backgroundColor: Colors.blueGrey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );

    battleVm.randomBattle(uid, attackerArmyOverride: selectedArmy).then((result) {
      // manejar resultado de batalla...
    }).catchError((e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error en PvP: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }
}

class PvpUnitRow extends StatelessWidget {
  final UnitType unit;
  final int maxQty;
  final int selQty;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  const PvpUnitRow({
    Key? key,
    required this.unit,
    required this.maxQty,
    required this.selQty,
    required this.onIncrement,
    required this.onDecrement,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Imagen de la unidad
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 80,
              height: 80,
              color: Colors.grey[800],
              child: Image.asset(
                unit.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(unit.emoji, style: const TextStyle(fontSize: 36)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre y estadísticas
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(unit.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('🗡️ ${unit.atk}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('🛡️ ${unit.def}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 8),
                    Text('❤️ ${unit.hp}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Disponibles: $maxQty', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          // Selector de cantidad
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, size: 20, color: Colors.white70),
                onPressed: onDecrement,
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: Text(
                  '$selQty',
                  key: ValueKey<int>(selQty),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20, color: Colors.white70),
                onPressed: onIncrement,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -------------------------------
// Snippet para BattleViewModel
// lib/viewmodels/battle_viewmodel.dart


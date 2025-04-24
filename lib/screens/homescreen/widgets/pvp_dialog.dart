import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:provider/provider.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:guild/viewmodels/battle_viewmodel.dart';

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
    setState(() => _isLoading = true);
    try {
      final uid = context.read<AuthViewModel>().user!.id;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      final armyMap = (data?['army'] as Map<String, dynamic>?) ?? {};

      final avail = <String, int>{};
      armyMap.forEach((unitId, qty) {
        if ((qty as int) > 0) {
          avail[unitId] = qty;
          _selected[unitId] = 0;
        }
      });

      setState(() {
        _available = avail;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar ejército: $e'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
@override
Widget build(BuildContext context) {
  return AlertDialog(
    backgroundColor: Colors.grey[900],
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    title: const Text('Duelo PvP', style: TextStyle(color: Colors.amber)),
    content: SizedBox(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.6,  // ocupa 60% de la pantalla
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _available.isEmpty
              ? const Center(
                  child: Text(
                    'No tienes unidades entrenadas',
                    style: TextStyle(color: Colors.white70),
                  ),
                )
              : ListView.separated(
                  itemCount: _available.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final unitId = _available.keys.elementAt(i);
                    final maxQty = _available[unitId]!;
                    final selQty = _selected[unitId]!;
                    final u = kUnitCatalog[unitId]!;

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Imagen más grande
                         ClipRRect(
  borderRadius: BorderRadius.circular(6),
  child: Container(
    width: 80,
    height: 80,
    color: Colors.grey[800], // opcional: fondo mientras carga la imagen
    child: Image.asset(
      u.imagePath,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          Center(child: Text(u.emoji, style: const TextStyle(fontSize: 36))),
    ),
  ),
),

                          const SizedBox(width: 12),

                          // Nombre, stats y disponibles
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(u.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('🗡️${u.atk}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Text('🛡️${u.def}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    const SizedBox(width: 8),
                                    Text('❤️${u.hp}',
                                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text('Disponibles: $maxQty',
                                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),

                          // Selectores + / –
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 20, color: Colors.white70),
                                onPressed: selQty > 0
                                    ? () => setState(() => _selected[unitId] = selQty - 1)
                                    : null,
                              ),
                              Text('$selQty',
                                  style: const TextStyle(color: Colors.white, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 20, color: Colors.white70),
                                onPressed: selQty < maxQty
                                    ? () => setState(() => _selected[unitId] = selQty + 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
      ),
      ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
        onPressed: _selected.values.every((v) => v == 0) ? null : _startBattle,
        child: const Text('¡Vamos!', style: TextStyle(color: Colors.black87)),
      ),
    ],
  );
}



  void _startBattle() {
    final uid = context.read<AuthViewModel>().user!.id;
    final vm = context.read<BattleViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final selectedArmy = Map<String, int>.from(_selected)
      ..removeWhere((_, cnt) => cnt == 0);

    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Tus unidades salen al combate…'),
        backgroundColor: Colors.blueGrey[800],
        behavior: SnackBarBehavior.floating,
      ),
    );

    vm.randomBattle(uid, attackerArmyOverride: selectedArmy).then((result) async {
      // … lógica de reporte en Firestore …
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

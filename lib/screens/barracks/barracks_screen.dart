import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/data/unit_catalog.dart' show kUnitCatalog;
import 'package:guild/models/unit_type.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart' show AuthViewModel;
import 'package:guild/viewmodels/barracks_viewmodel.dart';

/// Diálogo flotante de gestión de cuartel (toque fuera para cerrar)
class BarracksScreen extends StatefulWidget {
  const BarracksScreen({Key? key}) : super(key: key);

  @override
  State<BarracksScreen> createState() => _BarracksScreenState();
}

class _BarracksScreenState extends State<BarracksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Ahora solo dos pestañas: Ejército y Entrenar
    _tabController = TabController(length: 2, vsync: this);
    final uid = context.read<AuthViewModel>().user!.id;
    final vm = context.read<BarracksViewModel>();
    vm.initForUser(uid);
    vm.completeTrainings(uid);
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => vm.completeTrainings(uid),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BarracksViewModel>();
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: 360,
              height: 520,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Header con dos pestañas
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white70),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Expanded(
                          child: TabBar(
                            controller: _tabController,
                            labelColor: Colors.amber,
                            unselectedLabelColor: Colors.white60,
                            indicatorColor: Colors.amber,
                            tabs: const [
                              Tab(text: 'Ejército'),
                              Tab(text: 'Entrenar'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  // Vistas de pestañas
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        ArmyView(army: vm.army),
                        TrainView(vm: vm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista del ejército actual
class ArmyView extends StatelessWidget {
  final Map<String, int> army;
  const ArmyView({required this.army});

  @override
  Widget build(BuildContext context) {
    return army.isEmpty
        ? const Center(
            child: Text('Sin tropas',
                style: TextStyle(color: Colors.white70)),
          )
        : Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: army.entries.map((e) {
                final u = kUnitCatalog[e.key]!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UnitAvatar(unit: u, size: 60),
                    const SizedBox(height: 4),
                    Text('${e.value}',
                        style: const TextStyle(color: Colors.white)),
                  ],
                );
              }).toList(),
            ),
          );
  }
}

/// Entrenar: selector izquierdo + detalle derecho
class TrainView extends StatefulWidget {
  final BarracksViewModel vm;
  const TrainView({required this.vm});

  @override
  State<TrainView> createState() => _TrainViewState();
}

class _TrainViewState extends State<TrainView> {
  late List<UnitType> _available;
  late String _selected;
  int _quantity = 1;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final race = context.read<AuthViewModel>().user!.race;
    _available = kUnitCatalog.values
        .where((u) => u.requiredRace == null || u.requiredRace == race)
        .toList();
    _selected = _available.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user!.id;
    final unit = kUnitCatalog[_selected]!;

    return Row(
      children: [
        // Selector y cantidad - izquierda
        Container(
          width: 140,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _available.length,
                  itemBuilder: (_, i) {
                    final u = _available[i];
                    final sel = u.id == _selected;
                    return ListTile(
                      leading: UnitAvatar(unit: u, size: 50),
                      title: Text(u.name,
                          style: TextStyle(
                              color: sel ? Colors.amber : Colors.white70,
                              fontSize: 14)),
                      tileColor: sel ? Colors.grey[800] : null,
                      onTap: () => setState(() => _selected = u.id),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.remove,
                          color: Colors.white70),
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null),
                  Text('$_quantity',
                      style:
                          const TextStyle(color: Colors.white)),
                  IconButton(
                      icon: const Icon(Icons.add,
                          color: Colors.white70),
                      onPressed: _quantity < 99
                          ? () => setState(() => _quantity++)
                          : null),
                ],
              ),
              const SizedBox(height: 4),
              _loading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : TextButton(
                      onPressed: () async {
                        setState(() => _loading = true);
                        await widget.vm
                            .trainUnit(uid, _selected, _quantity);
                        setState(() => _loading = false);
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(6)),
                      ),
                      child: const Text('Entrenar',
                          style: TextStyle(
                              color: Colors.black87)),
                    ),
            ],
          ),
        ),
        // Detalle derecho horizontal
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[850],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Imagen más ancha
                AspectRatio(
                  aspectRatio: 1.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      unit.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(unit.emoji,
                            style: TextStyle(
                                fontSize: 48)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(unit.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  alignment: WrapAlignment.center,
                  children: unit.stats.entries
                      .map((e) => Column(
                            children: [
                              Text(e.key,
                                  style: const TextStyle(
                                      color: Colors.white60)),
                              Text(e.value.toString(),
                                  style: const TextStyle(
                                      color: Colors.white)),
                            ],
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
                Text(
                  'Costo entrenamiento:\nMadera ${unit.costWood}, Piedra ${unit.costStone}, Comida ${unit.costFood}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar de unidad como cuadrado
class UnitAvatar extends StatelessWidget {
  final UnitType unit;
  final double size;
  const UnitAvatar({required this.unit, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          unit.imagePath,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              unit.emoji,
              style: TextStyle(fontSize: size / 2),
            ),
          ),
        ),
      ),
    );
  }
}

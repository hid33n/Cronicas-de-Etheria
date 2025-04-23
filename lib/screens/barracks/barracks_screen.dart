import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild/data/unit_catalog.dart' show kUnitCatalog;
import 'package:guild/models/unit_type.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart' show AuthViewModel;
import 'package:guild/viewmodels/barracks_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';


/// Pantalla de gestión de cuartel con cola, ejército y entrenamiento
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
    _tabController = TabController(length: 3, vsync: this);
    final uid = context.read<AuthViewModel>().user!.id;
    final vm = context.read<BarracksViewModel>();
    vm.initForUser(uid);
    vm.completeTrainings(uid);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      vm.completeTrainings(uid);
    });
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
    return Scaffold(
      backgroundColor: Colors.black54,
      body: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340, maxHeight: 500),
              child: Material(
                color: Colors.grey[900],
                elevation: 24,
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    _CloseButton(),
                    _TabBar(controller: _tabController),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          QueueView(vm: vm),
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
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: IconButton(
        icon: const Icon(Icons.close, color: Colors.white70),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white60,
      indicatorColor: Colors.amber,
      tabs: const [Tab(text: 'Cola'), Tab(text: 'Ejército'), Tab(text: 'Entrenar')],
    );
  }
}


/// Vista de la cola de entrenamiento
class QueueView extends StatelessWidget {
  final BarracksViewModel vm;
  const QueueView({required this.vm});

  @override
  Widget build(BuildContext context) {
    final queue = vm.queue;
    final uid = context.read<AuthViewModel>().user!.id;
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: queue.isEmpty
          ? const Center(
              child: Text('Sin cola', style: TextStyle(color: Colors.white70)),
            )
          : ListView.builder(
              itemCount: queue.length,
              itemBuilder: (_, i) {
                final item = queue[i];
                final unit = kUnitCatalog[item.unitId]!;
                final pending = item.readyAt.isAfter(DateTime.now());
                return ListTile(
                  dense: true,
                  leading: UnitAvatar(unit: unit),
                  title: Text(unit.name,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(
                    pending
                        ? '${((item.readyAt.difference(DateTime.now()).inSeconds) / 60).ceil()} min'
                        : 'Listo',
                    style: TextStyle(
                      color: pending ? Colors.white70 : Colors.greenAccent,
                    ),
                  ),
                  trailing: pending
                      ? IconButton(
                          icon: const Icon(Icons.clear,
                              color: Colors.redAccent),
                          onPressed: () => vm.cancelTraining(uid, item.docId),
                        )
                      : const Text('OK',
                          style: TextStyle(color: Colors.greenAccent)),
                );
              },
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: army.isEmpty
          ? const Center(
              child: Text('Sin tropas', style: TextStyle(color: Colors.white70)),
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: army.entries.map((e) {
                final unit = kUnitCatalog[e.key]!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UnitAvatar(unit: unit),
                    const SizedBox(height: 4),
                    Text(e.value.toString(),
                        style: const TextStyle(color: Colors.white)),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
/// Vista para entrenar nuevas unidades con diseño mejorado
class TrainView extends StatefulWidget {
  final BarracksViewModel vm;
  const TrainView({required this.vm});

  @override
  State<TrainView> createState() => _TrainViewState();
}

class _TrainViewState extends State<TrainView> {
  late String _selectedUnit;
  int _quantity = 1;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final race = context.read<AuthViewModel>().user!.race;
    final available = kUnitCatalog.values.where((u) => u.requiredRace == null || u.requiredRace == race);
    _selectedUnit = available.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user!.id;
    final race = context.read<AuthViewModel>().user!.race;
    final available = kUnitCatalog.values.where((u) => u.requiredRace == null || u.requiredRace == race);

    final unit = kUnitCatalog[_selectedUnit]!;
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Detalle de la unidad en tarjeta
          Card(
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [UnitAvatar(unit: unit, radius: 30), const SizedBox(width: 12), Text(unit.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: unit.stats.entries.map((e) => Column(
                      children: [Text(e.key, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 4), Text(e.value.toString(), style: const TextStyle(color: Colors.white, fontSize: 16))],
                    )).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Selector de cantidad y unidades
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.remove, color: Colors.white70), onPressed: _quantity>1?(){setState(()=>_quantity--);} : null),
              Container(
                width: 50,
                alignment: Alignment.center,
                child: Text('$_quantity', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              IconButton(icon: const Icon(Icons.add, color: Colors.white70), onPressed: _quantity<99?(){setState(()=>_quantity++);} : null),
            ],
          ),

          const SizedBox(height: 12),
          // Lista de unidades disponibles
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: available.map((u) => GestureDetector(
                onTap: () => setState(() => _selectedUnit = u.id),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: u.id==_selectedUnit?Colors.grey[700]:Colors.grey[800],
                    border: u.id==_selectedUnit?Border.all(color:Colors.amber, width:2):null,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [UnitAvatar(unit: u, radius: 24), const SizedBox(height: 6), Expanded(child: Text(u.name, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis))],
                  ),
                ),
              )).toList(),
            ),
          ),

          const SizedBox(height: 12),
          // Botón entrenar
          SizedBox(
            width: double.infinity,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading=true);
                      try { await widget.vm.trainUnit(uid, _selectedUnit, _quantity); }
                      finally { setState(() => _isLoading=false); }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      padding: const EdgeInsets.symmetric(vertical:12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Entrenar', style: TextStyle(color: Colors.black87, fontSize:16)),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Avatar de unidad con imagen o emoji mejorado
class UnitAvatar extends StatelessWidget {
  final UnitType unit;
  final double radius;
  const UnitAvatar({required this.unit, this.radius=20});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[800],
      child: ClipOval(
        child: Image.asset(
          unit.imagePath,
          width: radius*1.8,
          height: radius*1.8,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Text(unit.emoji, style: TextStyle(fontSize: radius)),
        ),
      ),
    );
  }
}

/// Muestra detalles y stats de la unidad
class UnitDetail extends StatelessWidget {
  final UnitType unit;
  const UnitDetail({required this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UnitAvatar(unit: unit),
            const SizedBox(width: 8),
            Text(unit.name, style: const TextStyle(color: Colors.white)),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: unit.stats.entries.map((e) {
            return Column(
              children: [
                Text(e.key, style: const TextStyle(color: Colors.white60)),
                Text(e.value.toString(),
                    style: const TextStyle(color: Colors.white)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Control de cantidad con botones ±
class _QuantityControl extends StatelessWidget {
  final int quantity;
  final ValueChanged<int> onChanged;
  const _QuantityControl({required this.quantity, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.white60),
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Text('$quantity', style: const TextStyle(color: Colors.white)),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white60),
          onPressed: quantity < 99 ? () => onChanged(quantity + 1) : null,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/models/unit_type.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:guild/viewmodels/barracks_viewmodel.dart';

class BarracksScreen extends StatefulWidget {
  const BarracksScreen({Key? key}) : super(key: key);
  @override
  _BarracksScreenState createState() => _BarracksScreenState();
}

class _BarracksScreenState extends State<BarracksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tc;
  late final BarracksViewModel _vm;
  late final String _race;
  UnitType? _selected;
  int _qty = 1;
  bool _busy = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _vm = context.read<BarracksViewModel>();
    final uid = context.read<AuthViewModel>().user!.id;
    _vm.initForUser(uid);
    _vm.completeTrainings(uid);
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _vm.completeTrainings(uid),
    );
    _tc = TabController(length: 2, vsync: this);
    _race = context.read<AuthViewModel>().user!.race;
  }

  @override
  void dispose() {
    _tc.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Cuartel', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.grey[850],
        bottom: TabBar(
          controller: _tc,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Ejército'),
            Tab(text: 'Entrenar'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tc,
        children: [
          _buildArmyTab(),
          _buildTrainTab(),
        ],
      ),
    );
  }

  Widget _buildArmyTab() {
 final entries = _vm.army.entries
    .where((e) {
      final u  = kUnitCatalog[e.key]!;
      final rr = u.requiredRace;
      return (rr == null || rr.isEmpty || rr == _race) && e.value > 0;
    })
    .toList();  // <-- convierte el Iterable en List

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) {
        final e = entries[i];
        final u = kUnitCatalog[e.key]!;
        return _unitCard(u, count: e.value);
      },
    );
  }

  Widget _buildTrainTab() {
    // Todas las unidades disponibles para la raza
    final units = kUnitCatalog.values.where((u) {
  final rr = u.requiredRace;
  return rr == null || rr.isEmpty || rr == _race;
}).toList();

    _selected ??= units.first;
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: units.map((u) {
              final isSel = u.id == _selected!.id;
              return GestureDetector(
                onTap: () => setState(() => _selected = u),
                child: _unitCard(u, highlight: isSel),
              );
            }).toList(),
          ),
        ),
        _trainControl(),
      ],
    );
  }

  Widget _unitCard(UnitType u, {int? count, bool highlight = false}) {
  final bool isExclusive = u.requiredRace != null;

  return Container(
    decoration: BoxDecoration(
      color: highlight ? Colors.grey[700] : Colors.grey[850],
      borderRadius: BorderRadius.circular(8),
    ),
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isExclusive)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('🔱 Exclusivo',
                style: TextStyle(color: Colors.amber, fontSize: 12)),
          ),

        // 2) Expand la imagen para llenar el espacio disponible
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Image.asset(
              u.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Text(u.emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
        ),

        // 3) Nombre y stats al pie
        Text(u.name, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗡️ ${u.atk}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(width: 6),
            Text('🛡️ ${u.def}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const SizedBox(width: 6),
            Text('❤️ ${u.hp}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('#$count',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ],
        ),
      ],
    ),
  );
}


  Widget _trainControl() {
    final u = _selected!;
    final uid = context.read<AuthViewModel>().user!.id;
    final w = u.costWood * _qty;
    final s = u.costStone * _qty;
    final f = u.costFood * _qty;

    final totalSecs = u.baseTrainSecs * _qty;
    final dur = Duration(seconds: totalSecs);
    final minutes = dur.inMinutes;
    final seconds = dur.inSeconds % 60;
    final timeLabel = '${minutes}m ${seconds}s';

    return Container(
      color: Colors.grey[850],
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selector de cantidad
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              ),
              Text('$_qty', style: const TextStyle(color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _qty < 99 ? () => setState(() => _qty++) : null,
              ),
            ],
          ),

          // Costos con emojis
          Text('🪵 $w   🔹 $s   🍖 $f',
              style: const TextStyle(color: Colors.white70)),

          // Tiempo de entrenamiento
          const SizedBox(height: 4),
          Text('⏳ $timeLabel',
              style: const TextStyle(color: Colors.white70)),

          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    await _vm.trainUnit(uid, u.id, _qty);
                    setState(() => _busy = false);
                  },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('⏳ Entrenar',
                    style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }
}

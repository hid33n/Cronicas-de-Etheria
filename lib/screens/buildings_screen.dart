// lib/screens/buildings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/buildings/building_viewmodel.dart';
import '../data/building_catalog.dart';

class BuildingsScreen extends StatefulWidget {
  @override
  _BuildingsScreenState createState() => _BuildingsScreenState();
}

class _BuildingsScreenState extends State<BuildingsScreen> {
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      final uid = context.read<AuthViewModel>().user!.id;
      context.read<BuildingViewModel>().listenData(uid);
      _subscribed = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bVm = context.watch<BuildingViewModel>();
    final uid = context.read<AuthViewModel>().user!.id;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(title: Text('Edificios')),
      body: ListView(
        children: kBuildingCatalog.values.map((b) {
          final lvl      = bVm.levels[b.id] ?? 1;
          final nextLvl  = lvl + 1;
          final readyAt  = bVm.queue[b.id];
          final isBusy   = readyAt != null;

          // Costes y tiempo para nextLvl
          final woodCost  = b.baseCostWood  * nextLvl;
          final stoneCost = b.baseCostStone * nextLvl;
          final foodCost  = b.baseCostFood  * nextLvl;
          final timeSecs  = b.baseCostTime  * nextLvl;

          return Card(
            color: Color(0xFF2E2F31),
            margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            child: ListTile(
              leading: Text(b.assetPath, style: TextStyle(fontSize: 28)),
              title: Text(
                '${b.name}  (Lv $lvl → $nextLvl)',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: isBusy
  ? Text(
      // antes: readyAt!.toDate().difference(...)
      'Mejora lista en ${readyAt.difference(DateTime.now()).inMinutes} min',
      style: TextStyle(color: Colors.amber),
    )
  : Text(
      'Costes: 🪵$woodCost  🪨$stoneCost  🌾$foodCost  •  ${timeSecs ~/ 60} min',
      style: TextStyle(color: Colors.white70),
    ),
              trailing: isBusy
                  ? Icon(Icons.hourglass_top, color: Colors.white54)
                  : ElevatedButton(
                      onPressed: () => bVm.upgrade(uid, b.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                      ),
                      child: Text('Mejorar'),
                    ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

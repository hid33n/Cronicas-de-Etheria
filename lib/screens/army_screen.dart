import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/army_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../data/unit_catalog.dart';

class ArmyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user!.id;
    context.read<ArmyViewModel>().listenArmy(uid);
    final army = context.watch<ArmyViewModel>().army;

    return Scaffold(
      appBar: AppBar(title: Text('Ejército')),
      backgroundColor: Colors.grey[900],
      body: ListView(
        children: army.entries
            .where((e) => e.value > 0)
            .map((e) => ListTile(
                  leading: Icon(Icons.shield, color: Colors.amber),
                  title: Text(kUnitCatalog[e.key]!.name,
                      style: TextStyle(color: Colors.white)),
                  trailing: Text('x${e.value}',
                      style: TextStyle(color: Colors.white)),
                ))
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: Icon(Icons.face),
        label: Text('Atacar'),
        onPressed: () => Navigator.pushNamed(context, '/select_target'),
      ),
    );
  }
}

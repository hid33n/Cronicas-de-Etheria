// lib/screens/inventory_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/inventory_viewmodel.dart';

class InventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = context.watch<InventoryViewModel>().items;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Inventario', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No tienes ningún objeto en el inventario',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (_, idx) {
                  final item = items[idx];
                  return Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: ListTile(
                      leading: Icon(item.icon, color: Colors.amber, size: 32),
                      title: Text(
                        item.name,
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      subtitle: Text(
                        item.description,
                        style: TextStyle(color: Colors.white70),
                      ),
                      trailing: Text(
                        'x${item.quantity}',
                        style: TextStyle(color: Colors.amber, fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

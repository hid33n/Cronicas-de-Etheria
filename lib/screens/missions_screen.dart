// lib/screens/missions_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart';
import 'package:guild/viewmodels/mission_viewmodel.dart';
import 'package:guild/viewmodels/inventory_viewmodel.dart';

class MissionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authUser   = context.watch<AuthViewModel>().user;
    final missionVm  = context.watch<MissionViewModel>();
    final invVm      = context.read<InventoryViewModel>();
    final missions   = missionVm.missionsForCity(authUser?.cityId);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Row(
          children: [
            Icon(Icons.flag, color: Colors.amber),
            const SizedBox(width: 8),
            Text('Misiones Disponibles',
                style: TextStyle(
                    fontFamily: 'Cinzel',
                    color: Colors.amber,
                    fontSize: 20)),
          ],
        ),
      ),
      body: missions.isEmpty
          ? Center(
              child: Text('No hay misiones disponibles',
                  style: TextStyle(color: Colors.white70)))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: missions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final m = missions[i];
                return Card(
                  color: Colors.grey[800],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Título + tipo
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              child: Icon(Icons.task_alt,
                                  color: Colors.amber),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(m.title,
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Cinzel',
                                      fontSize: 18)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Descripción
                        Text(m.description,
                            style: TextStyle(
                                color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 12),
                        // Recompensas y botón
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Oro
                            Row(
                              children: [
                                Icon(Icons.monetization_on,
                                    color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('${m.rewardGold}',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                              ),
                              onPressed: () {
                                missionVm.completeMission(
                                    m.id, authUser as AuthViewModel, invVm);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Has completado "${m.title}" 🎉'),
                                  ),
                                );
                              },
                              child: Text('Completar',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontFamily: 'Cinzel')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

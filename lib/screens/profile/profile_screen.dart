import 'package:flutter/material.dart';
import 'package:guild/data/race_catalog.dart';
import 'package:guild/screens/profile/avatar_picker_dialog.dart';
import 'package:guild/viewmodels/inventory_viewmodel.dart';

import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  @override
  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final invVm  = context.watch<InventoryViewModel>();
    final user   = authVm.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        appBar: AppBar(
          title: Text('Perfil', style: TextStyle(fontFamily: 'Cinzel')),
          backgroundColor: Colors.black87,
        ),
        body: Center(
          child: Text('No estás autenticado',
              style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final race = kRaces.firstWhere((r) => r.id == user.race);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text('Mi Perfil', style: TextStyle(fontFamily: 'Cinzel')),
        backgroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Avatar tappable para cambiar ---
            Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => AvatarPickerDialog(),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.grey[700],
                        // Si avatarUrl empieza por "assets/", carga asset
                        backgroundImage: user.avatarUrl.startsWith('assets/')
                            ? AssetImage(user.avatarUrl) as ImageProvider
                            : (user.avatarUrl.isNotEmpty
                                ? NetworkImage(user.avatarUrl)
                                : null),
                        child: user.avatarUrl.isEmpty
                            ? Icon(Icons.person,
                                size: 48, color: Colors.white70)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(user.name,
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 24,
                            fontFamily: 'Cinzel')),
                    const SizedBox(height: 6),
                    Text(user.rank,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 12),
                  Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [

    const SizedBox(width: 8),
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
  '🏆 ${user.eloRating}',
  style: TextStyle(
    color: Colors.amber,
    fontSize: 14,
  ),
),

      ],
    ),
  ],
),

const SizedBox(height: 12),

// — Imagen de la raza —
if (race.assetPath.isNotEmpty)
  Image.asset(
    race.assetPath,
    width: 80,
    height: 80,
  ),

const SizedBox(height: 8),

// — Nombre de la raza —
Text(
  race.name,
  textAlign: TextAlign.center,
  style: TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Estadísticas principales ---
            Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statTile('Oro', '${user.gold}', Icons.monetization_on),
                    _statTile('Misiones', '${user.missionsCompleted}',
                        Icons.task_alt),
                    _statTile('Logros', '${user.achievements.length}',
                        Icons.emoji_events),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // --- Inventario ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Inventario',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontFamily: 'Cinzel')),
            ),
            const SizedBox(height: 8),
            invVm.items.isEmpty
                ? Text('Tu inventario está vacío',
                    style: TextStyle(color: Colors.white70))
                : SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: invVm.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final it = invVm.items[i];
                        return Column(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey[700],
                              child: Icon(it.icon,
                                  color: Colors.amber, size: 28),
                            ),
                            const SizedBox(height: 4),
                            Text(it.name,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                            Text('x${it.quantity}',
                                style: TextStyle(
                                    color: Colors.amber, fontSize: 12)),
                          ],
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            // --- Logros detallados ---
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Logros',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontFamily: 'Cinzel')),
            ),
            const SizedBox(height: 8),
            user.achievements.isNotEmpty
                ? Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.achievements
                        .map((trophy) => Chip(
                              avatar: Icon(Icons.star,
                                  color: Colors.yellowAccent, size: 18),
                              label:
                                  Text(trophy, style: TextStyle(color: Colors.white)),
                              backgroundColor: Colors.deepPurple,
                            ))
                        .toList(),
                  )
                : Text('Aún no tienes logros',
                    style: TextStyle(color: Colors.white70)),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }


  Widget _statTile(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

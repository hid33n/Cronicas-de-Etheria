import 'package:flutter/material.dart';
import 'package:guild/data/race_catalog.dart';
import 'package:guild/screens/profile/avatar_picker_dialog.dart';
import 'package:guild/services/audio_services.dart';
import 'package:guild/viewmodels/inventory_viewmodel.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final invVm  = context.watch<InventoryViewModel>();
    final user   = authVm.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: Text('No estás autenticado', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    final race = kRaces.firstWhere((r) => r.id == user.race);

    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),

                  // Avatar y datos del usuario
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
                              backgroundImage: user.avatarUrl.startsWith('assets/')
                                  ? AssetImage(user.avatarUrl) as ImageProvider
                                  : (user.avatarUrl.isNotEmpty
                                      ? NetworkImage(user.avatarUrl)
                                      : null),
                              child: user.avatarUrl.isEmpty
                                  ? Icon(Icons.person, size: 48, color: Colors.white70)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(user.name,
                              style: TextStyle(color: Colors.amber, fontSize: 24, fontFamily: 'Cinzel')),
                          const SizedBox(height: 6),
                          Text(user.rank, style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 12),
                          Text('🏆 ${user.eloRating}', style: TextStyle(color: Colors.amber, fontSize: 14)),
                          const SizedBox(height: 12),
                          if (race.assetPath.isNotEmpty)
                            Image.asset(race.assetPath, width: 80, height: 80),
                          const SizedBox(height: 8),
                          Text(race.name, textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Estadísticas principales
                  Card(
                    color: Colors.grey[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _statTile('Oro', '${user.gold}', Icons.monetization_on),
                          _statTile('Misiones', '${user.missionsCompleted}', Icons.task_alt),
                          _statTile('Logros', '${user.achievements.length}', Icons.emoji_events),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Inventario
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Inventario', style: TextStyle(color: Colors.amber, fontSize: 18, fontFamily: 'Cinzel')),
                  ),
                  const SizedBox(height: 8),
                  invVm.items.isEmpty
                      ? Text('Tu inventario está vacío', style: TextStyle(color: Colors.white70))
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
                                  CircleAvatar(radius: 24, backgroundColor: Colors.grey[700], child: Icon(it.icon, color: Colors.amber, size: 28)),
                                  const SizedBox(height: 4),
                                  Text(it.name, style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('x${it.quantity}', style: TextStyle(color: Colors.amber, fontSize: 12)),
                                ],
                              );
                            },
                          ),
                        ),

                  const SizedBox(height: 24),

                  // Logros detallados
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Logros', style: TextStyle(color: Colors.amber, fontSize: 18, fontFamily: 'Cinzel')),
                  ),
                  const SizedBox(height: 8),
                  user.achievements.isNotEmpty
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: user.achievements.map((t) => Chip(
                                avatar: Icon(Icons.star, color: Colors.yellowAccent, size: 18),
                                label: Text(t, style: TextStyle(color: Colors.white)),
                                backgroundColor: Colors.deepPurple,
                              )).toList(),
                        )
                      : Text('Aún no tienes logros', style: TextStyle(color: Colors.white70)),

                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Gear icon for settings
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: Icon(Icons.settings, color: Colors.white70),
                onPressed: () => _openSettings(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    final authVm = context.read<AuthViewModel>();
    final audioSvc = context.read<AudioService>();
    double currentVolume = 0.5; // TODO: obtener valor actual del AudioService

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setState) {
            final canChangeName = authVm.canChangeName(authVm.user?.lastNameChange);

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajustes', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Opción cambiar nombre
                  ListTile(
                    leading: Icon(Icons.edit, color: canChangeName ? Colors.white : Colors.white24),
                    title: Text('Cambiar nombre', style: TextStyle(color: canChangeName ? Colors.white : Colors.white24)),
                    onTap: canChangeName ? () {
                      // TODO: abrir diálogo de cambio de nombre
                    } : null,
                  ),

                  // Control de volumen
                  ListTile(
                    leading: Icon(Icons.volume_up, color: Colors.white),
                    title: Text('Volumen', style: TextStyle(color: Colors.white)),
                    subtitle: Slider(
                      value: currentVolume,
                      min: 0,
                      max: 1,
                      onChanged: (v) {
                        setState(() => currentVolume = v);
                        // TODO: implementar método setVolume en AudioService
                        audioSvc.setVolume(v);
                      },
                    ),
                  ),

                  // Opción cerrar sesión
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.redAccent),
                    title: Text('Cerrar sesión', style: TextStyle(color: Colors.redAccent)),
                    onTap: () {
                      authVm.signOut();
                      Navigator.of(context).pushReplacementNamed('/login');
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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

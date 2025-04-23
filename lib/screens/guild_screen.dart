// lib/screens/guild_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/guild_viewmodel.dart';
import '../viewmodels/chat_viewmodel.dart';
import 'city_chat_screen.dart';

class GuildScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authVm  = context.watch<AuthViewModel>();
    final guildVm = context.read<GuildViewmodel>();
    final chatVm  = context.read<ChatViewModel>();

    final user      = authVm.user!;
    final guildId   = ModalRoute.of(context)!.settings.arguments as String? ?? user.cityId!;
    final guild = guildVm.getCityById(guildId);
if (guild == null) {
  // Si no existe el gremio, redirigimos al home inmediatamente
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.pushReplacementNamed(context, '/main');
  });
  // Mientras tanto mostramos un loader
  return Scaffold(
    backgroundColor: Colors.grey[900],
    body: Center(child: CircularProgressIndicator(color: Colors.amber)),
  );
}
    final isMayor   = user.id == guild.mayorId;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.black87,
        centerTitle: true,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(guild.iconAsset, width: 36, height: 36, fit: BoxFit.cover),
            ),
            const SizedBox(width: 8),
            Text(
              guild.name,
              style: TextStyle(fontFamily: 'Cinzel', color: Colors.amber, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.forum, color: Colors.amber),
            tooltip: 'Chat de Gremio',
            onPressed: () {
              chatVm.initCityChat(guild.id);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: chatVm,
                  child: CityChatScreen(),
                ),
              ));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Estadísticas
            Card(
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCard('Miembros', '${guild.residents.length}', Icons.group),
                    _statCard('Trofeos', '${guild.trophies}', Icons.emoji_events),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users').doc(guild.mayorId).get(),
                      builder: (ctx, snap) {
                        final mayor = snap.hasData
                            ? (snap.data?.get('name') as String? ?? '—')
                            : '…';
                        return _statCard('Alcalde', mayor, Icons.person);
                      },
                    ),
                  ],
                ),
              ),
            ),

            Spacer(),

            // Acciones según rol y tamaño del gremio
            if (isMayor) ...[
              if (guild.residents.length > 1)
                ElevatedButton(
                  onPressed: () async {
                    // Elegimos un nuevo alcalde al azar
                    final others = guild.residents.where((u) => u != user.id).toList();
                    final newMayor = (others..shuffle()).first;
                    final ok1 = await guildVm.transferLeadership(guild.id, newMayor);
                    final ok2 = ok1 && await guildVm.leaveGuild(guild.id, user.id);
                    if (ok2) {
                      await authVm.setCityId(null);
                      Navigator.pushReplacementNamed(context, '/main');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  ),
                  child: Text('Transferir Liderazgo y Abandonar', style: TextStyle(color: Colors.black87)),
                ),
              const SizedBox(height: 12),
             ElevatedButton(
  onPressed: () async {
    final ok = await guildVm.disbandGuild(guild.id);
    if (ok) {
      // 1) Quitamos el cityId del usuario
      await authVm.setCityId(null);
      // 2) Vamos a la Home (MainNavScreen) y borramos todo el Stack
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.redAccent,
    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
  ),
  child: Text('Disolver Gremio', style: TextStyle(color: Colors.white)),
),

            ] else ...[
              ElevatedButton.icon(
                onPressed: () async {
                  final ok = await guildVm.leaveGuild(guild.id, user.id);
                  if (ok) {
                    await authVm.setCityId(null);
                    Navigator.pushReplacementNamed(context, '/splash');
                  }
                },
                icon: Icon(Icons.exit_to_app, color: Colors.white),
                label: Text('Abandonar Gremio', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 28),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Cinzel')),
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }


}

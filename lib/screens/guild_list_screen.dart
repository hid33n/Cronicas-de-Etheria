// lib/screens/guild_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/guild_viewmodel.dart';


class GuildListScreen extends StatefulWidget {
  const GuildListScreen({Key? key}) : super(key: key);

  @override
  _GuildListScreenState createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen> {


  @override
  Widget build(BuildContext context) {
    final guildVm     = context.watch<GuildViewmodel>();
    final authVm      = context.watch<AuthViewModel>();
    final currentUser = authVm.user;

    // Mientras el redirect se ejecuta dejamos un placeholder
    if (currentUser?.cityId != null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final guilds = guildVm.cities;

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_moon, color: Colors.amber, size: 28),
            const SizedBox(width: 8),
            Text(
              'Gremios',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 22,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        elevation: 2,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Barra de búsqueda
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar gremio...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.amber),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) {
                // TODO: implementar filtrado
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: guilds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final g   = guilds[i];
                  return Card(
                    color: Colors.grey[800],
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                   child: Padding(
  padding: const EdgeInsets.symmetric(
      vertical: 12, horizontal: 16),
  child: Row(
    children: [
      CircleAvatar(
        radius: 24,
        backgroundColor: Colors.black87,
        backgroundImage: AssetImage(g.iconAsset),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              g.name,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Cinzel',
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              g.description,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.group, size: 16, color: Colors.white54),
                const SizedBox(width: 4),
                Text('${g.residents.length}', style: const TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text('${g.trophies}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        icon: const Icon(Icons.login, size: 16, color: Colors.black87),
        label: const Text('Unirse',
            style: TextStyle(color: Colors.black87, fontSize: 14)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        onPressed: () async {
          final joined = await guildVm.joinCity(g.id, currentUser!.id);
          if (joined) {
            Navigator.pushReplacementNamed(context, '/city', arguments: g.id);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se pudo unir al gremio.')),
            );
          }
        },
      ),
    ],
  ),
),

                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new_guild',
        backgroundColor: Colors.amber[700],
        icon: const Icon(Icons.add, color: Colors.black87),
        label: const Text(
          'Forjar Gremio',
          style: TextStyle(color: Colors.black87, fontFamily: 'Cinzel'),
        ),
        onPressed: () =>
            Navigator.pushNamed(context, '/city_action'),
      ),
    );
  }
}

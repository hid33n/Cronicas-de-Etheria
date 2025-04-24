import 'package:flutter/material.dart';
import 'package:guild/screens/create_guild_screen.dart';
import 'package:guild/screens/guild_screen/guild_screen.dart';
import 'package:guild/screens/main_nav_screen.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth/auth_viewmodel.dart';
import '../viewmodels/guild/guild_viewmodel.dart';

class GuildListScreen extends StatefulWidget {
  const GuildListScreen({Key? key}) : super(key: key);

  @override
  _GuildListScreenState createState() => _GuildListScreenState();
}

class _GuildListScreenState extends State<GuildListScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final guildVm = context.watch<GuildViewmodel>();
    final authVm = context.watch<AuthViewModel>();
    final currentUser = authVm.user;

    if (currentUser?.cityId != null) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final allGuilds = guildVm.cities;
    final guilds = _search.isEmpty
        ? allGuilds
        : allGuilds.where((g) {
            final q = _search.toLowerCase();
            return g.name.toLowerCase().contains(q) ||
                   g.description.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.shield_moon, color: Colors.amber, size: 24),
            SizedBox(width: 8),
            Text(
              'Gremios',
              style: TextStyle(
                fontFamily: 'Cinzel',
                fontSize: 20,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black87,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Search bar
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar gremio...',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (q) => setState(() => _search = q),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: guilds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) {
                  final g = guilds[i];
                  return Card(
                    color: Colors.grey[800],
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.black87,
                                backgroundImage: AssetImage(g.iconAsset),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  g.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cinzel',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      // Dentro de GuildListScreen.itemBuilder:
IconButton(
  icon: const Icon(Icons.login, size: 20),
  color: Colors.amber,
// Al unirte al gremio (en GuildListScreen)
onPressed: () async {
  final joined = await guildVm.joinCity(g.id, currentUser!.id);
  if (!joined) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No se pudo unir al gremio.')),
    );
    return;
  }
  // 1) Actualiza el cityId
  await authVm.setCityId(g.id);
  // 2) Vuelve a MainNavScreen, limpia todo el stack y muestra la pestaña Gremio
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(
      builder: (_) => MainNavScreen(initialIndex: 1),
    ),
    (route) => false,
  );
},


),

      
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            g.description,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.group,
                                size: 16,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${g.residents.length}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(width: 16),
                              const Icon(
                                Icons.emoji_events,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${g.trophies}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
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
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 5,
        ),
        child: FloatingActionButton(
          heroTag: 'new_guild',
          backgroundColor: Colors.amber[600],
          child: const Text('🔨', style: TextStyle(fontSize: 26)),
          onPressed: () async {
            await showCreateGuildDialog(context);
          },
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

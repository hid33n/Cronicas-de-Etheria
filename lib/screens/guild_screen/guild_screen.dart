import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guild/models/user_model.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';
import '../../viewmodels/guild/guild_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../city_chat_screen.dart';
import '../main_nav_screen.dart';  // Para regresar a la pestaña Gremio

/// Pantalla completa de detalle de gremio.
class GuildDetailScreen extends StatelessWidget {
  final String guildId;
  const GuildDetailScreen({required this.guildId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final guildVm = context.watch<GuildViewmodel>();
    final chatVm = context.read<ChatViewModel>();
    final user = authVm.user!;
    final guild = guildVm.getCityById(guildId);

    if (guild == null) {
      // Si no existe el gremio (p.ej. se abandonó), volver al MainNavScreen en la pestaña Gremio
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavScreen(initialIndex: 1),
          ),
        );
      });
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
      );
    }

    final isMayor = user.id == guild.mayorId;

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A2A2A),
        elevation: 0,
        title: Row(
          children: [
            ClipOval(
              child: Image.asset(
                guild.iconAsset,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                guild.name,
                style: const TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 22,
                  color: Colors.amber,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.forum, color: Colors.amber),
              tooltip: 'Chat de Gremio',
              onPressed: () {
                chatVm.initCityChat(guild.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeNotifierProvider.value(
                      value: chatVm,
                      child: CityChatScreen(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Estadísticas
           // Estadísticas (dentro del Row)
Card(
  color: const Color(0xFF2A2A2A),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statItem('Miembros', '${guild.residents.length}', Icons.group),
        _statItem('Trofeos', '${guild.trophies}', Icons.emoji_events),
        FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(guild.mayorId)
              .get(),
          builder: (ctx, snap) {
            final leaderName = snap.hasData
              ? (snap.data?.get('name') as String? ?? '—')
              : '…';
            return _statItem('Líder', leaderName, Icons.person); // etiqueta cambiada
          },
        ),
      ],
    ),
  ),
),

const SizedBox(height: 24),

// Miembros en lista vertical
const Text(
  'Miembros',
  style: TextStyle(
    color: Colors.amber,
    fontFamily: 'Cinzel',
    fontSize: 18,
  ),
),
const SizedBox(height: 12),
// Asegúrate de que exista el asset 'assets/avatars/default.png' en tu pubspec.yaml

ListView.separated(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: guild.residents.length,
  separatorBuilder: (_, __) => const Divider(color: Colors.grey),
  itemBuilder: (ctx, i) {
    final memberId = guild.residents[i];
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(memberId)
          .get(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return ListTile(
            leading: CircleAvatar(backgroundColor: Colors.grey[700]),
            title: const Text('…', style: TextStyle(color: Colors.white)),
          );
        }
        final data   = snap.data!;
        final name   = (data.get('name')      as String?) ?? '—';
        final elo    = (data.get('eloRating') as int?)    ?? 0;
        final avatar = (data.get('avatarUrl') as String?) ?? '';

        // Decide la imagen: si avatar es URL o asset, y por defecto un asset genérico
        final ImageProvider imageProvider = avatar.isEmpty
          ? const AssetImage('assets/avatars/avatar1.png')
          : (avatar.startsWith('http')
              ? NetworkImage(avatar)
              : AssetImage(avatar)) as ImageProvider;

        // Calcula el rango
        final tempUser = UserModel(
          id: memberId,
          name: name,
          avatarUrl: avatar,
          eloRating: elo,
          race: data.get('race') as String? ?? '',
        );
        final rank = tempUser.rank;

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: imageProvider,
            backgroundColor: Colors.grey[700],
          ),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          subtitle: Row(
            children: [
              Text(rank, style: const TextStyle(color: Colors.white70)),
              const SizedBox(width: 8),
              const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
              const SizedBox(width: 4),
              Text('$elo', style: const TextStyle(color: Colors.white70)),
            ],
          ),
         // Dentro de tu ListTile:
trailing: memberId == user.id
  ? PopupMenuButton<String>(
      icon: const Icon(Icons.exit_to_app, color: Colors.redAccent),
      color: const Color(0xFF2A2A2A),
      onSelected: (action) async {
        switch (action) {
          case 'leave':
            // Abandonar gremio
            final okLeave = await guildVm.leaveGuild(guild.id, user.id);
            if (!okLeave) return;
            await authVm.setCityId(null);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MainNavScreen(initialIndex: 1)),
              (route) => false,
            );
            break;

          case 'transfer':
            // Transferir liderazgo (elige al azar un nuevo líder)
            final others = guild.residents.where((u) => u != user.id).toList()..shuffle();
            final newMayor = others.first;
            final ok1 = await guildVm.transferLeadership(guild.id, newMayor);
            final ok2 = ok1 && await guildVm.leaveGuild(guild.id, user.id);
            if (!ok2) return;
            await authVm.setCityId(null);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MainNavScreen(initialIndex: 1)),
              (route) => false,
            );
            break;

          case 'disband':
            // Disolver gremio
            final okDis = await guildVm.disbandGuild(guild.id);
            if (!okDis) return;
            await authVm.setCityId(null);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => MainNavScreen(initialIndex: 1)),
              (route) => false,
            );
            break;
        }
      },
      itemBuilder: (ctx) {
        // Si eres el líder, ofreces las 3 opciones...
        if (isMayor) {
          return [
            const PopupMenuItem(value: 'transfer', child: Text('🔄 Transferir Liderazgo')),
            const PopupMenuItem(value: 'disband',  child: Text('💥 Disolver Gremio')),
          ];
        } 
        // ...si no, sólo dejar el gremio
        return [
          const PopupMenuItem(value: 'leave',    child: Text('🚪 Abandonar Gremio')),
        ];
      },
    )
  : null,

        );
      },
    );
  },
),


const SizedBox(height: 24),

            
            ],
        ),
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 26),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Cinzel')),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class PvpInfoScreen extends StatelessWidget {
  const PvpInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user!.id;
    final reportsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pvp_reports')
        .orderBy('timestamp', descending: true)
        .snapshots();
    final rankingStream = FirebaseFirestore.instance
        .collection('users')
        .orderBy('eloRating', descending: true)
        .limit(20)
        .snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[900],
        body: SafeArea(
          child: Column(
            children: [
              TabBar(
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white70,
                tabs: const [
                  Tab(icon: Icon(Icons.list), text: 'Informes'),
                  Tab(icon: Icon(Icons.leaderboard), text: 'Ranking'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Informes de Batalla
                    StreamBuilder<QuerySnapshot>(
                      stream: reportsStream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text('Error: \${snap.error}', style: const TextStyle(color: Colors.redAccent)),
                          );
                        }
                        if (snap.connectionState != ConnectionState.active) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return const Center(
                            child: Text('Sin informes de batalla', style: TextStyle(color: Colors.white70)),
                          );
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: docs.length,
                          itemBuilder: (context, i) {
                            final doc = docs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final oppId = data['opponentId'] as String;
                            final won = data['attackerWon'] as bool;
                            final elo = data['eloDelta'] as int;
                            final survA = Map<String, int>.from(data['survivorsAttacker'] ?? {});
                            final lossA = Map<String, int>.from(data['lossesAttacker'] ?? {});
                            final survD = Map<String, int>.from(data['survivorsDefender'] ?? {});
                            final lossD = Map<String, int>.from(data['lossesDefender'] ?? {});
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              color: Colors.grey[800],
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('users').doc(oppId).get(),
                                  builder: (context, uSnap) {
                                    final oppName = (uSnap.hasData && uSnap.data!.data() != null)
                                        ? (uSnap.data!.data()! as Map<String, dynamic>)['name'] as String? ?? oppId
                                        : oppId;
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              won ? '🏆 Victoria' : '💀 Derrota',
                                              style: TextStyle(
                                                color: won ? Colors.greenAccent : Colors.redAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Vs. $oppName',
                                                style: const TextStyle(color: Colors.amber),
                                              ),
                                            ),
                                            Text(
                                              'Elo: ${elo >= 0 ? '+' : ''}$elo',
                                              style: TextStyle(
                                                color: elo >= 0 ? Colors.greenAccent : Colors.redAccent,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.white70),
                                              onPressed: () async {
                                                try {
                                                  await FirebaseFirestore.instance
                                                      .collection('users')
                                                      .doc(uid)
                                                      .collection('pvp_reports')
                                                      .doc(doc.id)
                                                      .delete();
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Informe eliminado'),
                                                      backgroundColor: Colors.blueGrey,
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error al eliminar: $e'),
                                                      backgroundColor: Colors.red[700],
                                                      behavior: SnackBarBehavior.floating,
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        const Divider(color: Colors.white24),
                                        Wrap(
                                          spacing: 6, runSpacing: 4,
                                          children: [
                                            for (var e in survA.entries)
                                              Text('🛡️${kUnitCatalog[e.key]!.emoji}${e.value}', style: const TextStyle(color: Colors.white70)),
                                            for (var e in lossA.entries)
                                              Text('💥${kUnitCatalog[e.key]!.emoji}${e.value}', style: const TextStyle(color: Colors.white70)),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6, runSpacing: 4,
                                          children: [
                                            for (var e in survD.entries)
                                              Text('🛡️${kUnitCatalog[e.key]!.emoji}${e.value}', style: const TextStyle(color: Colors.white70)),
                                            for (var e in lossD.entries)
                                              Text('💥${kUnitCatalog[e.key]!.emoji}${e.value}', style: const TextStyle(color: Colors.white70)),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    // Tab 2: Ranking de Elo
                    StreamBuilder<QuerySnapshot>(
                      stream: rankingStream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text('Error: ${snap.error}', style: const TextStyle(color: Colors.redAccent)),
                          );
                        }
                        if (snap.connectionState != ConnectionState.active) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final users = snap.data?.docs ?? [];
                        return ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: users.length,
                          itemBuilder: (context, idx) {
                            final u = users[idx];
                            final d = u.data() as Map<String, dynamic>;
                            final name = d['name'] as String? ?? 'Sin nombre';
                            final race = d['race'] as String? ?? 'Desconocida';
                            final eloVal = d['eloRating'] as int? ?? 1000;
                            final avatarUrl = d['avatarUrl'] as String?;
                            return ListTile(
                              leading: Builder(
                                builder: (ctx) {
                                  ImageProvider? imageProvider;
                                  if (avatarUrl != null && avatarUrl.isNotEmpty) {
                                    if (avatarUrl.startsWith('assets/')) {
                                      imageProvider = AssetImage(avatarUrl);
                                    } else {
                                      imageProvider = NetworkImage(avatarUrl);
                                    }
                                  }
                                  return CircleAvatar(
                                    backgroundImage: imageProvider,
                                    backgroundColor: Colors.grey[700],
                                    child: imageProvider == null
                                        ? const Icon(Icons.person, color: Colors.white54)
                                        : null,
                                  );
                                },
                              ),
                              title: Text(name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text('Raza: $race', style: const TextStyle(color: Colors.white70)),
                              trailing: Text('⭐ $eloVal', style: const TextStyle(color: Colors.amber)),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

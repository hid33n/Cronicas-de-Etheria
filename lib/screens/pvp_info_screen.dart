import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:guild/data/race_catalog.dart';
import 'package:guild/data/unit_catalog.dart';
import 'package:guild/models/battle_report_model.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:provider/provider.dart';

class PvpInfoScreen extends StatelessWidget {
  const PvpInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthViewModel>().user!.id;
    final reportsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('battleReports')
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
              // ─── Pestañas RPG Minimal ─────────────────────────────
              Container(
                color: Colors.grey[850],
                child: TabBar(
                  indicator: UnderlineTabIndicator(
                    borderSide: BorderSide(width: 3, color: Colors.amber),
                    insets: EdgeInsets.symmetric(horizontal: 32),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.1,
                  ),
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white54,
                  tabs: const [
                    Tab(text: 'Informes'),
                    Tab(text: 'Ranking'),
                  ],
                ),
              ),

              Expanded(
                child: TabBarView(
                  children: [
                // Dentro de tu PvpInfoScreen, reemplaza solo la parte del Tab 1 por esto:

StreamBuilder<QuerySnapshot>(
  stream: reportsStream,
  builder: (context, snap) {
    if (snap.hasError) {
      return Center(
        child: Text('Error: ${snap.error}', style: TextStyle(color: Colors.redAccent)),
      );
    }
    if (snap.connectionState != ConnectionState.active) {
      return const Center(child: CircularProgressIndicator());
    }
    final docs = snap.data!.docs;
    if (docs.isEmpty) {
      return const Center(
        child: Text('Sin informes de batalla', style: TextStyle(color: Colors.white70)),
      );
    }
return ListView.builder(
  padding: const EdgeInsets.all(12),
  itemCount: docs.length,
  itemBuilder: (context, i) {
    final report = BattleReport.fromDoc(docs[i]);
    final survA = report.survivorsAttacker;
    final lossA = report.lossesAttacker;
    final survD = report.survivorsDefender;
    final lossD = report.lossesDefender;

    return Card(
  color: Colors.grey[850],
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  margin: const EdgeInsets.symmetric(vertical: 8),
  child: Padding(
    padding: const EdgeInsets.all(12),
    child: FutureBuilder<List<DocumentSnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection('users').doc(report.attackerId).get(),
        FirebaseFirestore.instance.collection('users').doc(report.defenderId).get(),
      ]),
      builder: (context, nameSnap) {
        if (!nameSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final atkDoc = nameSnap.data![0];
        final defDoc = nameSnap.data![1];
        final atkName = (atkDoc.data() as Map<String, dynamic>)['name'] as String? ?? report.attackerId;
        final defName = (defDoc.data() as Map<String, dynamic>)['name'] as String? ?? report.defenderId;
        final survA = report.survivorsAttacker;
        final lossA = report.lossesAttacker;
        final survD = report.survivorsDefender;
        final lossD = report.lossesDefender;
        final uid = context.read<AuthViewModel>().user!.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con nombres, ELO y botón de eliminar
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Atacante
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Atacante: $atkName',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'Elo: ${report.eloDeltaAttacker >= 0 ? '+' : ''}${report.eloDeltaAttacker}',
                            style: TextStyle(
                              color: report.eloDeltaAttacker >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Defensor
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Defensor: $defName',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            'Elo: ${report.eloDeltaDefender >= 0 ? '+' : ''}${report.eloDeltaDefender}',
                            style: TextStyle(
                              color: report.eloDeltaDefender >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Botón de eliminar
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white70),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .collection('battleReports')
                            .doc(report.id)
                            .delete();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Informe eliminado'),
                            backgroundColor: Colors.blueGrey,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Error al eliminar: $e'),
                            backgroundColor: Colors.red[700],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),

            const Divider(color: Colors.white24),

            // Tropas de Ataque
            const Text(
              '⚔️ Tropas de Ataque',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: survA.entries
                  .where((e) => kUnitCatalog.containsKey(e.key))
                  .map((e) {
                    final unit = kUnitCatalog[e.key]!;
                    return Text(
                      '🛡️${unit.emoji}${e.value}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: lossA.entries
                  .where((e) => kUnitCatalog.containsKey(e.key))
                  .map((e) {
                    final unit = kUnitCatalog[e.key]!;
                    return Text(
                      '💥${unit.emoji}${e.value}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  })
                  .toList(),
            ),

            const SizedBox(height: 12),

            // Tropas de Defensa
            const Text(
              '🛡️ Tropas de Defensa',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: survD.entries
                  .where((e) => kUnitCatalog.containsKey(e.key))
                  .map((e) {
                    final unit = kUnitCatalog[e.key]!;
                    return Text(
                      '🛡️${unit.emoji}${e.value}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  })
                  .toList(),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: lossD.entries
                  .where((e) => kUnitCatalog.containsKey(e.key))
                  .map((e) {
                    final unit = kUnitCatalog[e.key]!;
                    return Text(
                      '💥${unit.emoji}${e.value}',
                      style: const TextStyle(color: Colors.white70),
                    );
                  })
                  .toList(),
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

                    // ─── Tab 2: Ranking ────────────────────────────────
                    StreamBuilder<QuerySnapshot>(
                      stream: rankingStream,
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(
                            child: Text(
                              'Error: ${snap.error}',
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }
                        if (snap.connectionState != ConnectionState.active) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final users = snap.data?.docs ?? [];
                        return ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: users.length,
                          itemBuilder: (context, idx) {
                            final d      = users[idx].data() as Map<String, dynamic>;
                            final name   = d['name']      as String? ?? 'Sin nombre';
                            final raceId = d['race']      as String? ?? '';
                            final eloVal = d['eloRating'] as int?    ?? 1000;
                            final avatar = d['avatarUrl'] as String?;

                            final raceObj = kRaces.firstWhere(
                              (r) => r.id == raceId,
                              orElse: () => kRaces.first,
                            );

                            return Card(
                              color: Colors.grey[850],
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.grey[800],
                                  backgroundImage: (avatar != null && avatar.isNotEmpty)
                                      ? (avatar.startsWith('assets/')
                                          ? AssetImage(avatar)
                                          : NetworkImage(avatar))
                                      : null,
                                  child: (avatar == null || avatar.isEmpty)
                                      ? const Icon(Icons.person, color: Colors.white54)
                                      : null,
                                ),
                                title: Text(
                                  name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Cinzel',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Row(
                                  children: [
                                    // Imagen de la raza
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: AssetImage(raceObj.assetPath),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      raceObj.name,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontFamily: 'Cinzel',
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$eloVal',
                                        style: TextStyle(
                                          color: Colors.amber,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

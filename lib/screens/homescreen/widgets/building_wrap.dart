// lib/screens/home_screen/widgets/building_wrap.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/building_catalog.dart';
import '../../../viewmodels/buildings/building_viewmodel.dart';
import '../../../viewmodels/auth/auth_viewmodel.dart';

class BuildingWrap extends StatelessWidget {
  const BuildingWrap({super.key});

  @override
  Widget build(BuildContext context) {
    final bldVm = context.watch<BuildingViewModel>();
    final uid   = context.read<AuthViewModel>().user!.id;
    final width = MediaQuery.of(context).size.width;
    final cardW = (width - 16 * 3) / 2;

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: kBuildingCatalog.values.map((b) {
        final lvl     = bldVm.levels[b.id] ?? 1;
        final nextLvl = lvl + 1;
        final readyAt = bldVm.queue[b.id];
        final busy    = readyAt != null;
        final woodCost  = b.baseCostWood  * nextLvl;
        final stoneCost = b.baseCostStone * nextLvl;
        final foodCost  = b.baseCostFood  * nextLvl;
        final mins      = (b.baseCostTime * nextLvl) ~/ 60;

        return SizedBox(
          width: cardW,
          child: Card(
            color: const Color(0xFF2E2F31),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // badge + emoji
                  Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lv $lvl',
                        style: const TextStyle(color: Colors.black87, fontSize: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(b.assetPath, style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 4),
                  Text(
                    b.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  // estado de mejora o botón
                  if (busy) ...[
                    Icon(Icons.hourglass_top, color: Colors.amber, size: 24),
                    const SizedBox(height: 4),
                    Builder(builder: (_) {
                      final remaining = readyAt.difference(DateTime.now());
                      if (remaining > Duration.zero) {
                        return Text(
                          '${remaining.inMinutes} min',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        );
                      } else {
                        return Text(
                          'Listo',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                        );
                      }
                    }),
                  ] else ...[
                    Text('→ Lv $nextLvl',
                        style: const TextStyle(color: Colors.amber, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '🪵$woodCost 🪨$stoneCost 🌾$foodCost\n⏱️ ${mins}m',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () async {
                        try {
                          await bldVm.upgrade(uid, b.id);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Mejora de ${b.name} iniciada…')),
                          );
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      child: const Text(
                        'Up',
                        style: TextStyle(color: Colors.black87, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

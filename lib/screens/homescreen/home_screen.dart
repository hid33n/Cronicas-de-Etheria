// lib/screens/home_screen/home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:guild/screens/global_chat_message.dart';
import 'package:provider/provider.dart';
import 'package:guild/data/building_catalog.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:guild/viewmodels/buildings/building_viewmodel.dart';
import 'package:guild/screens/homescreen/widgets/building_dialog.dart';
import 'package:guild/screens/homescreen/widgets/res_chip.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final String _uid;
  Timer? _upgradeTimer;
  Timer? _uiTimer;      // <-- nuevo

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _uid = context.read<AuthViewModel>().user!.id;
      final bldVm = context.read<BuildingViewModel>();
      bldVm.listenData(_uid);
      bldVm.collectResources(_uid);
      bldVm.completeUpgrades(_uid);
      _upgradeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        bldVm.completeUpgrades(_uid);
      });
            // 2) nuevo: cada segundo redibujo para actualizar el countdown
      _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    
    });
  }

  @override
  void dispose() {
    _upgradeTimer?.cancel();
     _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final bldVm  = context.watch<BuildingViewModel>();
    final user   = authVm.user!;
    final prod   = bldVm.productionPerHour;
    final topPad = MediaQuery.of(context).padding.top + 8;


    // Calculo actual de mejoras en curso
    final upgrades = bldVm.upgradeTimeLeft;

    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        // ─── MAPA FULLSCREEN ─────────────────────────
        Image.asset(
          'assets/images/terrain_bg.png',
          fit: BoxFit.fill,
          filterQuality: FilterQuality.high,
        ),

        // ─── EDIFICIOS SOBRE EL FONDO ───────────────
        ...kBuildingCatalog.values.map((b) {
          final lvl = bldVm.levels[b.id] ?? 1;
          final ax = b.position.dx * 2 - 1;
          final ay = b.position.dy * 2 - 1;
          return Align(
            alignment: Alignment(ax, ay),
            child: GestureDetector(
              onTap: () => showDialog(
                context: context,
                builder: (_) => BuildingDialog(building: b, level: lvl,     uid: _uid,  ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Image.asset(
                    b.assetPath,
                    width: b.width,
                    height: b.height,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  if (b.id != 'coliseo')
                    Text(
                      'Lv $lvl',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),

        // ─── BARRA DE RECURSOS FIJA ───────────────────
        Positioned(
          top: topPad,
          left: 0,
          right: 0,
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceEvenly,
            children: [
              ResChip.minimal('assets/resources/wood.png',
                  qty: bldVm.resources['wood'] ?? 0,
                  perHour: prod['lumbermill'] ?? 0),
              ResChip.minimal('assets/resources/stone.png',
                  qty: bldVm.resources['stone'] ?? 0,
                  perHour: prod['stonemine'] ?? 0),
              ResChip.minimal('assets/resources/food.png',
                  qty: bldVm.resources['food'] ?? 0,
                  perHour: prod['farm'] ?? 0),
              ResChip.minimal('assets/resources/gold.png',
                  qty: user.gold, perHour: 0),
            ],
          ),
        ),

      // ─── INDICADOR DE MEJORAS (miniaturas con contenedor) ───────────────────

if (upgrades.isNotEmpty)
  Positioned(
    top: topPad + 80,
    right: 2,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(84, 0, 0, 0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título de la cola
          const Text(
            'Cola',
            style: TextStyle(

              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),

          // Lista de mejoras en curso
          ...upgrades.entries.map((e) {
            final b = kBuildingCatalog[e.key]!;
            final rem = e.value;
            final mm = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
            final ss = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
return Padding(
  padding: const EdgeInsets.only(bottom: 4),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        b.assetPath,
        width: 24,
        height: 24,
        fit: BoxFit.contain,
      ),
      const SizedBox(width: 4),
      Text(
        '$mm:$ss',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      // ── Aquí la X roja ──
      const SizedBox(width: 6),
     // dentro de upgrades.entries.map((e) { … })
GestureDetector(
  onTap: () {
    final vm = context.read<BuildingViewModel>();
    // 1) calculamos niveles y costes
    final currentLvl = vm.levels[e.key] ?? 1;
    final nextLvl    = currentLvl + 1;
    final bType      = kBuildingCatalog[e.key]!;

    final woodCost   = bType.baseCostWood  * nextLvl;
    final stoneCost  = bType.baseCostStone * nextLvl;
    final foodCost   = bType.baseCostFood  * nextLvl;

    final woodRefund  = (woodCost  * 0.5).floor();
    final stoneRefund = (stoneCost * 0.5).floor();
    final foodRefund  = (foodCost  * 0.5).floor();

    // 2) mostramos diálogo con emojis y cantidades
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          '🛡️ Cancelar mejora',
          style: TextStyle(color: Colors.amber),
        ),
        content: Text(
          'Solo recuperarás el 50 % de los recursos gastados:\n'
          '🪵 $woodRefund   🪨 $stoneRefund   🌾 $foodRefund\n\n'
          '¿Estás seguro?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text('❌ No', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('✅ Sí', style: TextStyle(color: Colors.white)),
            onPressed: () {
              // 3) si confirman, cancelamos la mejora y cerramos todo
              vm.cancelUpgrade(_uid, e.key);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  },
  child: Container(
    width: 18,
    height: 18,
    decoration: const BoxDecoration(
      color: Colors.redAccent,
      shape: BoxShape.circle,
    ),
    child: const Icon(
      Icons.close,
      size: 14,
      color: Colors.white,
    ),
  ),
),

    ],
  ),
);
          }
          ).toList(),
        ],
      ),
    ),
  ),


        // ─── CHAT GLOBAL ────────────────────────
        const GlobalChatWidget(),
      ]),
    );
  }
}

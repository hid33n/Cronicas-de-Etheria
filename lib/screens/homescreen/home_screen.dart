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
    });
  }

  @override
  void dispose() {
    _upgradeTimer?.cancel();
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
                builder: (_) => BuildingDialog(building: b, level: lvl),
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

        // ─── INDICADOR DE MEJORAS ────────────────────
        if (upgrades.isNotEmpty)
          Positioned(
            top: topPad + 48,
            left: 16,
            right: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: upgrades.entries.map((e) {
                    final b = kBuildingCatalog[e.key]!;
                    final rem = e.value;
                    final mm = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
                    final ss = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
                    return Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Text(
                        '🔧 ${b.name}: $mm:$ss',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

        // ─── CHAT GLOBAL ────────────────────────
        const GlobalChatWidget(),
      ]),
    );
  }
}

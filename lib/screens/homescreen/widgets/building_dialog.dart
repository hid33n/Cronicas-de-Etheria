import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:guild/screens/barracks/barracks_screen.dart';
import 'package:guild/screens/homescreen/widgets/pvp_dialog.dart';
import 'package:guild/services/audio_services.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:guild/models/building_type.dart';
import 'package:guild/viewmodels/buildings/building_viewmodel.dart';

class BuildingDialog extends StatefulWidget {
  final BuildingType building;
  final int level;
  final String uid;   
  const BuildingDialog({
    required this.building,
    required this.level,
    required this.uid
  });

  @override
  State<BuildingDialog> createState() => _BuildingDialogState();
}
class _BuildingDialogState extends State<BuildingDialog> {
  late final AudioService _audioSvc;
  late final StreamSubscription<PlayerState> _sfxSub;

  @override
  void initState() {
    super.initState();
    _audioSvc = context.read<AudioService>();

    // 1) Pausamos la música de fondo
    _audioSvc.pauseBackground();

    // 2) Disparamos el SFX
    _audioSvc.playSfx(widget.building.id);

    // 3) Nos suscribimos para saber cuándo termina el SFX
    _sfxSub = _audioSvc.onSfxStateChanged.listen((state) {
      if (state == PlayerState.completed && mounted) {
        // Reanudar fondo cuando el SFX complete
        _audioSvc.resumeBackground();
      }
    });
  }

  @override
  void dispose() {
    _sfxSub.cancel();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final bldVm = context.watch<BuildingViewModel>();
    final nextLevel = widget.level + 1;
    final woodCost = widget.building.baseCostWood * nextLevel;
    final stoneCost = widget.building.baseCostStone * nextLevel;
    final foodCost = widget.building.baseCostFood * nextLevel;
    final secs = widget.building.baseCostTime * nextLevel;
    final res   = bldVm.resources;
    final hasWood  = (res['wood']  ?? 0) >= woodCost;
final hasStone = (res['stone'] ?? 0) >= stoneCost;
final hasFood  = (res['food']  ?? 0) >= foodCost;
    final canAfford = hasWood && hasStone && hasFood;

    final mins = (secs / 60).ceil();
    final uid = context.read<AuthViewModel>().user!.id;
final readyAt       = bldVm.queue[widget.building.id];
  final isUnderUpgrade = readyAt != null && readyAt.isAfter(DateTime.now());

    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        widget.building.name,
        style: const TextStyle(color: Colors.amber),
      ),
      content: widget.building.id == 'coliseo'
    ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            widget.building.assetPath,
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          const Text(
            '¡Desafía a otros jugadores en duelos gloriosos y escala en el ranking de honor!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.sports_mma, color: Colors.black87),
            label: const Text('Iniciar PvP', style: TextStyle(color: Colors.black87)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (_) => const PvpDialog(),
              );
            },
          ),
        ],
      )

    : Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        widget.building.assetPath,
        width: 48,
        height: 48,
        fit: BoxFit.contain,
      ),
      const SizedBox(height: 8),
      Text(
        'Nivel actual: ${widget.level}',
        style: const TextStyle(color: Colors.white70),
      ),
      const Divider(color: Colors.white24),
      Text('► Mejora a nivel $nextLevel', style: const TextStyle(color: Colors.amber)),
      const SizedBox(height: 6),
      Text(
        'Coste: 🪵 $woodCost   🪨 $stoneCost   🌾 $foodCost',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70),
      ),
      const SizedBox(height: 4),
      Text('Tiempo: ⏱️ $mins min', style: const TextStyle(color: Colors.white70)),
      const SizedBox(height: 16),
    // ─── BOTÓN DE MEJORA CON ESTADO ─────────────────
if (isUnderUpgrade)
  ElevatedButton.icon(
    onPressed: null,
    icon: const Icon(Icons.upgrade, color: Colors.grey),
    label: const Text('Ya mejorando',
        style: TextStyle(color: Colors.grey)),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
  )
else if (!canAfford)
  ElevatedButton.icon(
    onPressed: null,
    icon: const Icon(Icons.warning_amber_rounded, color: Colors.grey),
    label: const Text('Recursos insuficientes',
        style: TextStyle(color: Colors.grey)),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
  )
else
  ElevatedButton.icon(
    icon: const Icon(Icons.upgrade, color: Colors.black87),
    label: Text('Mejorar a Lv $nextLevel',
        style: const TextStyle(color: Colors.black87)),
    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
    onPressed: () {
      Navigator.of(context).pop();
      context
        .read<BuildingViewModel>()
        .upgrade(widget.uid, widget.building.id)
        .then((error) {
          if (error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(error),
                backgroundColor: Colors.red[600],
              ),
            );
          }
        });
    },
  ),
      if (widget.building.id == 'barracks') ...[
        const SizedBox(height: 12),
        ElevatedButton.icon(
          icon: const Icon(Icons.group, color: Colors.black87),
          label: const Text('Entrenar tropas', style: TextStyle(color: Colors.black87)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          onPressed: () {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => const BarracksScreen(),
            );
          },
        ),
      ],
    ],
  ),

  );
   }
    }
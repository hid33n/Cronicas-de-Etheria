// lib/widgets/race_selector.dart
import 'package:flutter/material.dart';
import '../data/race_catalog.dart';

class RaceSelector extends StatefulWidget {
  final void Function(String raceId) onSelected;
  const RaceSelector({required this.onSelected, Key? key}) : super(key: key);

  @override
  _RaceSelectorState createState() => _RaceSelectorState();
}

class _RaceSelectorState extends State<RaceSelector> {
  String _race = kRaces.first.id;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final selectedRace = kRaces.firstWhere((r) => r.id == _race);

    return Column(
      children: [
        // ===== Scroll horizontal de miniaturas cuadradas =====
        SizedBox(
          height: 110,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: kRaces.map((r) {
                final isSel = r.id == _race;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _race = r.id;
                        _confirmed = false;
                      });
                      // Preview más grande
                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: '',
                        transitionDuration: const Duration(milliseconds: 100),
                       
                        pageBuilder: (_, __, ___) => Center(
                          child: Hero(
                            tag: r.id,
                            child: SizedBox(
                              width: 350,
                              height: 350,
                              child: Image.asset(r.assetPath, fit: BoxFit.fill),
                            ),
                          ),
                        ),
                        transitionBuilder: (_, anim, __, child) {
                          return ScaleTransition(
                            scale: CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOut,
                            ),
                            child: child,
                          );
                        },
                      );
                    },
                    child: Hero(
                      tag: r.id,
                      child: Container(
                        width: 80,
                        height: 110,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSel ? Colors.amber : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: AssetImage(r.assetPath),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ===== Nombre y lore =====
        Text(
          selectedRace.name,
          style: const TextStyle(
            color: Colors.amber,
            fontFamily: 'Cinzel',
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          selectedRace.lore,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70),
        ),

        const SizedBox(height: 16),

        // ===== Confirmar selección =====
        if (!_confirmed)
          ElevatedButton.icon(
            icon: const Icon(Icons.check, color: Colors.black87),
            label: const Text('Elegir esta raza',
                style: TextStyle(color: Colors.black87)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              widget.onSelected(_race);
              setState(() => _confirmed = true);
            },
          )
        else
          const Text('✅ Raza seleccionada',
              style: TextStyle(color: Colors.greenAccent)),
      ],
    );
  }
}

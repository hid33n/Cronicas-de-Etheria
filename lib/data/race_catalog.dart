// lib/data/race_catalog.dart

import '../models/race.dart';

const List<Race> kRaces = [
  Race(
    id: 'human',
    name: 'Humanos de Valiar',
    emoji: '🛡️',
    lore:
        'Mercaderes versátiles que prosperaron tras el Cataclismo. '
        'Sus caballeros portan el estandarte dorado de Valiar.',
    assetPath: 'assets/races/human.png',      // ← tu PNG
  ),
  Race(
    id: 'elf',
    name: 'Elfos Silvanos',
    emoji: '🌲',
    lore:
        'Custodios de los bosques cantores. Sus arqueros son casi invisibles '
        'entre las copas esmeralda.',
    assetPath: 'assets/races/elf.png',
  ),
  Race(
    id: 'dwarf',
    name: 'Enanos Ferrum',
    emoji: '⛏️',
    lore:
        'Forjadores de acero vivo bajo las Montañas Grises. Sus martillos '
        'retumban desde antes del Cataclismo.',
    assetPath: 'assets/races/dwarf.png',
  ),
  Race(
    id: 'arcanian',
    name: 'Arcanianos Forjados',
    emoji: '⚙️',
    lore:
        'Hijos de la simbiosis entre magia y engranajes. Sus autómatas guardan '
        'secretos de era perdida.',
    assetPath: 'assets/races/arcanian.png',
  ),
  Race(
    id: 'drakari',
    name: 'Drakari',
    emoji: '🐉',
    lore:
        'Descendientes de linaje dracónico. Su aliento ardiente infunde respeto '
        'y miedo por igual.',
    assetPath: 'assets/races/drakari.png',
  ),
];

// lib/models/race.dart

class Race {
  final String id;
  final String name;
  final String emoji;
  final String lore;
  final String assetPath; // ← ruta al PNG

  const Race({
    required this.id,
    required this.name,
    required this.emoji,
    required this.lore,
    required this.assetPath,
  });
}

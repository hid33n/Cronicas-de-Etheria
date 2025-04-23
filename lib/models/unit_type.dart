class UnitType {
  final String id;
  final String name;
  final String emoji;
  final String imagePath;
  final String? requiredRace;
  final int hp, atk, def, baseTrainSecs, capacity;
  final int costWood, costStone, costFood;

  UnitType({
    required this.id,
    required this.name,
    required this.emoji,
    required this.imagePath,
    this.requiredRace,
    required this.hp,
    required this.atk,
    required this.def,
    required this.baseTrainSecs,
    required this.capacity,
    required this.costWood,
    required this.costStone,
    required this.costFood,
  });

  /// Genera un map de stats para mostrar en UI
  Map<String, int> get stats => {
    'HP': hp,
    'ATK': atk,
    'DEF': def,
  };
}

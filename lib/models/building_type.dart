import 'dart:ui';

class BuildingType {
  final String id;       // ej. 'barracks'
  final String name;     // 'Cuartel'
  final String assetPath;   // 🏰
  final Offset position;
  final int baseCost;    // en oro para nivel 1
  final int baseTime;    // seg. de construcción nivel 1
  final int prodPerHour; // solo para edificios de recurso
    final int baseCostTime;    // seg. para nivel 1
  final int baseCostWood;    // madera para nivel 1
  final int baseCostStone;   // piedra para nivel 1
  final int baseCostFood;    // comida para nivel 1
  final double width;
  final double height;
  static const int globalMaxLevel = 35;
  static const int normalBuildingMaxLevel = 34;

  const BuildingType({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.baseCost,
    required this.baseTime,
    required this.position,
    required this.baseCostTime,
    required this.baseCostWood,
    required this.baseCostStone,
    required this.baseCostFood,
    this.height = 124,
    this.width = 124,
    this.prodPerHour = 0,
  });

   /// Nivel máximo permitido para este edificio
  int getMaxLevel() {
    return id == 'warehouse' ? globalMaxLevel : normalBuildingMaxLevel;
  }

  /// Para el almacén: interpola capacidad desde 1500 (lvl1) hasta 50000 (lvl35)
  int getMaxStorage(int level) {
    assert(id == 'warehouse');
    final lvl = level.clamp(1, getMaxLevel());
    return (1500 + ((50000 - 1500) / (getMaxLevel() - 1)) * (lvl - 1)).round();
  }
}


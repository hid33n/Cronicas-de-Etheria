// lib/data/building_catalog.dart

import 'dart:ui';
import '../models/building_type.dart';

const kBuildingCatalog = <String, BuildingType>{
  'townhall': BuildingType(
    id: 'townhall',
    name: 'Ayuntamiento',
    assetPath: 'assets/buildings/townhall.png',
    baseCost: 200,
    baseTime: 120,
    baseCostTime: 120,
    baseCostWood: 120,
    baseCostStone: 120,
    baseCostFood: 120,
    // Centro exacto del mapa (0.5, 0.5)
    position: Offset(0.7, 0.2),
    width: 164,
    height: 164,
  ),

  'warehouse': BuildingType(
    id: 'warehouse',
    name: 'Almacenamiento',
    assetPath: 'assets/buildings/warehouse.png',
    baseCost: 200,
    baseTime: 120,
    baseCostTime: 120,
    baseCostWood: 60,
    baseCostStone: 30,
    baseCostFood: 20,
    // Izquierda-centro
    position: Offset(0.2, 0.06),
    width: 84,
    height: 84,
  ),

  'barracks': BuildingType(
    id: 'barracks',
    name: 'Cuartel',
    assetPath: 'assets/buildings/barracks.png',
    baseCost: 200,
    baseTime: 120,
    baseCostTime: 120,
    baseCostWood: 100,
    baseCostStone: 50,
    baseCostFood: 75,
    // Derecha-centro
    position: Offset(0.3, 0.36),
    width: 94,
    height: 94,
  ),

  'lumbermill': BuildingType(
    id: 'lumbermill',
    name: 'Aserradero',
    assetPath: 'assets/buildings/sawmill.png',
    baseCost: 150,
    baseTime: 90,
    baseCostTime: 90,
    baseCostWood: 80,
    baseCostStone: 40,
    baseCostFood: 60,
    prodPerHour: 30,
    // Arriba–derecha
    position: Offset(0.7, 0.65),
    width: 84,
    height: 84,
  ),

  'stonemine': BuildingType(
    id: 'stonemine',
    name: 'Mina de Piedra',
    assetPath: 'assets/buildings/stonemine.png',
    baseCost: 150,
    baseTime: 90,
    baseCostTime: 90,
    baseCostWood: 80,
    baseCostStone: 40,
    baseCostFood: 60,
    prodPerHour: 20,
    // Arriba–izquierda
    position: Offset(0.3, 0.70),
    width: 84,
    height: 84,
  ),

  'farm': BuildingType(
    id: 'farm',
    name: 'Granja',
    assetPath: 'assets/buildings/farm.png',
    baseCost: 100,
    baseTime: 60,
    baseCostTime: 60,
    baseCostWood: 60,
    baseCostStone: 30,
    baseCostFood: 50,
    prodPerHour: 50,
    // Abajo–centro
    position: Offset(0.94, 0.80),
    width: 94,
    height: 94,
  ),
  'coliseo': BuildingType(
    id: 'coliseo',
    name: 'Coliseo',
    assetPath: 'assets/buildings/coliseo.png',
    baseCost: 100,
    baseTime: 60,
    baseCostTime: 60,
    baseCostWood: 60,
    baseCostStone: 30,
    baseCostFood: 50,
    prodPerHour: 50,
    // Abajo–centro
    position: Offset(0.1, 0.52),
    width: 94,
    height: 94,
  ),
};

import 'package:guild/models/item_model.dart';

/// Representa un rango y el Elo mínimo para alcanzarlo
class RankThreshold {
  final String name;
  final int minElo;
  const RankThreshold(this.name, this.minElo);
}

class UserModel {
  final String id;
  String name;
  String avatarUrl;
  String? cityId;
  int gold;
  String race;
  int eloRating;
  int missionsCompleted;
  List<String> achievements;
  List<ItemModel> inventory;

  UserModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.eloRating,
    this.missionsCompleted = 0,
    List<String>? achievements,
    this.cityId,
    this.gold = 0,
    List<ItemModel>? inventory,
    required this.race,
  })  : achievements = achievements ?? [],
        inventory = inventory ?? [];

  /// Copia este UserModel cambiando sólo los campos indicados.
  UserModel copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? cityId,
    int? gold,
    String? race,
    int? eloRating,
    int? missionsCompleted,
    List<String>? achievements,
    List<ItemModel>? inventory,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      eloRating: eloRating ?? this.eloRating,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      achievements: achievements ?? List.from(this.achievements),
      cityId: cityId ?? this.cityId,
      gold: gold ?? this.gold,
      inventory: inventory ?? List.from(this.inventory),
      race: race ?? this.race,
    );
  }

  /// Umbrales de rango con nombres medievales y requisitos más altos
  static const List<RankThreshold> _ranks = [
    RankThreshold('Peón',       0),     // 0–1499
    RankThreshold('Escudero',   1500),  // 1500–2999
    RankThreshold('Caballero',  3000),  // 3000–4999
    RankThreshold('Señor',      5000),  // 5000–7999
    RankThreshold('Barón',      8000),  // 8000–11999
    RankThreshold('Duque',      12000), // 12000–17999
    RankThreshold('Rey',        18000), // ≥18000
  ];

  /// Devuelve el rango actual según el Elo.
  String get rank {
    return _ranks
      .lastWhere((r) => eloRating >= r.minElo)
      .name;
  }
}

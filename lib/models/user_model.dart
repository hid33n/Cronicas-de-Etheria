import 'package:guild/models/item_model.dart';

class UserModel {
  final String id;
  String name;
  String avatarUrl;
  String? cityId;
  String rank;
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
    this.rank = 'Ciudadano',
    this.gold = 0,
    List<ItemModel>? inventory,
    required this.race
  }) : achievements = achievements ?? [],
   inventory = inventory ?? [];
}
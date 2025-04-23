import 'package:guild/models/item_model.dart';

class MissionModel {
  final String id;
  String title, description;
  int rewardGold;
  List<ItemModel> rewardItems;
  String cityId;
  bool isCompleted;

  MissionModel({
    required this.id,
    required this.title,
    required this.description,
    this.rewardGold = 10,
    List<ItemModel>? rewardItems,
    required this.cityId,
    this.isCompleted = false,
  }) : rewardItems = rewardItems ?? [];
}
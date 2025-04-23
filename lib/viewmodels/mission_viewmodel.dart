
import 'package:flutter/material.dart';
import 'package:guild/models/item_model.dart';
import 'package:guild/models/mission_model.dart';
import 'package:guild/viewmodels/auth/auth_viewmodel.dart';
import 'package:guild/viewmodels/inventory_viewmodel.dart';

class MissionViewModel extends ChangeNotifier {
  final List<MissionModel> _missions = [];

  List<MissionModel> missionsForCity(String? cityId) {
    if (cityId == null) return [];
    return _missions.where((m) => m.cityId == cityId && !m.isCompleted).toList();
  }

  void createMission({
    required String title,
    required String description,
    int rewardGold = 10,
    List<ItemModel>? rewardItems,
    required String cityId,
  }) {
    _missions.add(MissionModel(
      id: DateTime.now().toString(),
      title: title,
      description: description,
      rewardGold: rewardGold,
      rewardItems: rewardItems,
      cityId: cityId,
    ));
    notifyListeners();
  }

  void completeMission(String missionId, AuthViewModel auth, InventoryViewModel inventoryVm) {
    final mission = _missions.firstWhere((m) => m.id == missionId);
    mission.isCompleted = true;
    if (auth.user != null) {
      auth.user!.gold += mission.rewardGold;
      for (var item in mission.rewardItems) {
        inventoryVm.addItem(item);
      }
    }
    notifyListeners();
  }
}


import 'package:flutter/material.dart';
import 'package:guild/models/item_model.dart';
import 'package:guild/viewmodels/auth_viewmodel.dart';

class InventoryViewModel extends ChangeNotifier {
  final List<ItemModel> _items = [];
  List<ItemModel> get items => _items;

  void addItem(ItemModel item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index == -1) {
      _items.add(item);
    } else {
      _items[index].quantity += item.quantity;
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void buyItem(ItemModel item, AuthViewModel auth) {
    if (auth.user != null && auth.user!.gold >= item.price) {
      auth.user!.gold -= item.price;
      addItem(item);
    }
  }

  void sellItem(String itemId, AuthViewModel auth) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && auth.user != null) {
      auth.user!.gold += _items[index].price;
      _items.removeAt(index);
      notifyListeners();
    }
  }
}

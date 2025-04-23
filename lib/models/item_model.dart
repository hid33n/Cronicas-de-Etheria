import 'package:flutter/material.dart';

class ItemModel {
  final String id;
  String name, description;
  IconData icon;
  int quantity, price;

  ItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.quantity = 1,
    this.price = 0,
  });
}

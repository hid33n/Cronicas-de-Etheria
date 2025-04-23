// lib/models/city_model.dart

import 'package:flutter/material.dart';

class CityModel {
  final String id;
  final String name;
  final String mayorId;
  final double taxRate;
  final double x, y;
   final String iconAsset;
  final List<String> residents;
  final String description;  // nueva
  final int trophies;        // nueva

  CityModel({
    required this.id,
    required this.name,
    required this.mayorId,
    required this.taxRate,
    required this.x,
    required this.y,
    required this.iconAsset,
    required this.residents,
    required this.description,
    required this.trophies,
  });
}

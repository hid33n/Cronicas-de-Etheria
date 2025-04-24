// lib/models/city_model.dart

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

   /// Crea una copia de este CityModel reemplazando sólo los campos que le pases.
  CityModel copyWith({
    String? id,
    String? name,
    String? mayorId,
    double? taxRate,
    double? x,
    double? y,
    String? iconAsset,
    List<String>? residents,
    String? description,
    int? trophies,
  }) {
    return CityModel(
      id:          id          ?? this.id,
      name:        name        ?? this.name,
      mayorId:     mayorId     ?? this.mayorId,
      taxRate:     taxRate     ?? this.taxRate,
      x:           x           ?? this.x,
      y:           y           ?? this.y,
      iconAsset:   iconAsset   ?? this.iconAsset,
      residents:   residents   ?? List.from(this.residents),
      description: description ?? this.description,
      trophies:    trophies    ?? this.trophies,
    );
  }
}

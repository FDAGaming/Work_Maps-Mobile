class CategoryModel {
  final int id;
  final String name;
  final String icon;
  final String color;
  final int placeCount;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.placeCount,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as int,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      color: json['color'] ?? '#000000',
      placeCount: json['place_count'] ?? 0,
    );
  }
}

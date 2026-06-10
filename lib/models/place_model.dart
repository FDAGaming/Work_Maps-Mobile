class PlaceModel {
  final int id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final String description;
  final String? phone;
  final String? openHours;
  final String? website;
  final String? photoUrl;
  final List<String> tags;
  final String? priceRange;
  final double rating;
  final int reviewCount;
  final bool isVerified;
  final int categoryId;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;

  PlaceModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.description,
    this.phone,
    this.openHours,
    this.website,
    this.photoUrl,
    required this.tags,
    this.priceRange,
    required this.rating,
    required this.reviewCount,
    required this.isVerified,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as int,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lng: double.tryParse(json['lng'].toString()) ?? 0.0,
      description: json['description'] ?? '',
      phone: json['phone'],
      openHours: json['open_hours'],
      website: json['website'],
      photoUrl: json['photo_url'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      priceRange: json['price_range'],
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      reviewCount: json['review_count'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      categoryIcon: json['category_icon'] ?? '',
      categoryColor: json['category_color'] ?? '#000000',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'address': address,
        'lat': lat,
        'lng': lng,
        'description': description,
        'phone': phone,
        'openHours': openHours,
        'photoUrl': photoUrl,
        'tags': tags,
        'priceRange': priceRange,
        'rating': rating,
        'reviewCount': reviewCount,
        'categoryName': categoryName,
        'categoryIcon': categoryIcon,
        'categoryColor': categoryColor,
      };
}

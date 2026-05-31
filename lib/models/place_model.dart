class PlaceModel {
  final String id;
  final String name;
  final String categoryId;
  final String address;
  final double latitude;
  final double longitude;
  final String description;
  final double rating;
  final String photoUrl;

  PlaceModel({
    required this.id, required this.name, required this.categoryId,
    required this.address, required this.latitude, required this.longitude,
    required this.description, required this.rating, required this.photoUrl,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'].toString(),
      name: json['name'],
      categoryId: json['category_id'].toString(),
      address: json['address'],
      // Parsing aman untuk tipe data desimal/koordinat
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      description: json['description'],
      rating: double.parse(json['rating'].toString()),
      photoUrl: json['photo_url'],
    );
  }
}
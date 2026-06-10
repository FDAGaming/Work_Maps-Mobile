class ReviewModel {
  final int id;
  final int rating;
  final String comment;
  final String createdAt;
  final String userName;
  final String? userAvatar;

  ReviewModel({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.userName,
    this.userAvatar,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as int,
      rating: json['rating'] as int,
      comment: json['comment'] ?? '',
      createdAt: json['created_at'] ?? '',
      userName: json['user_name'] ?? 'Pengguna',
      userAvatar: json['user_avatar'],
    );
  }
}

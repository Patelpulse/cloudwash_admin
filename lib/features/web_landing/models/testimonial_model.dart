class TestimonialModel {
  final String id;
  final String name;
  final String role;
  final String message;
  final double rating;
  final String imageUrl;
  final bool isActive;

  TestimonialModel({
    required this.id,
    required this.name,
    required this.role,
    required this.message,
    required this.rating,
    required this.imageUrl,
    required this.isActive,
  });

  factory TestimonialModel.fromJson(Map<String, dynamic> json) {
    return TestimonialModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      role: json['role'] ?? '',
      message: json['message'] ?? '',
      rating: (json['rating'] ?? 5).toDouble(),
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'role': role,
      'message': message,
      'rating': rating,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}

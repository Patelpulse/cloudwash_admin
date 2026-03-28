class BlogModel {
  final String id;
  final String title;
  final String description;
  final String image;
  final String author;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  BlogModel({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.author,
    this.createdAt,
    this.updatedAt,
    required this.isActive,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      author: json['author'] ?? 'Admin',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'image': image,
      'author': author,
      'isActive': isActive,
    };
  }
}

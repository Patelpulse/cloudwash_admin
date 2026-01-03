class HeroSectionModel {
  final String id;
  final String tagline;
  final String mainTitle;
  final String description;
  final String buttonText;
  final String imageUrl;
  final String? youtubeUrl;
  final bool isActive;

  HeroSectionModel({
    required this.id,
    required this.tagline,
    required this.mainTitle,
    required this.description,
    required this.buttonText,
    required this.imageUrl,
    this.youtubeUrl,
    required this.isActive,
  });

  factory HeroSectionModel.fromJson(Map<String, dynamic> json) {
    return HeroSectionModel(
      id: json['_id'] ?? '',
      tagline: json['tagline'] ?? '',
      mainTitle: json['mainTitle'] ?? '',
      description: json['description'] ?? '',
      buttonText: json['buttonText'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      youtubeUrl: json['youtubeUrl'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'tagline': tagline,
      'mainTitle': mainTitle,
      'description': description,
      'buttonText': buttonText,
      'imageUrl': imageUrl,
      'youtubeUrl': youtubeUrl,
      'isActive': isActive,
    };
  }
}

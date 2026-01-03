class AboutUsModel {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final int experienceYears;
  final String imageUrl;
  final List<String> points;
  final bool isActive;

  AboutUsModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.experienceYears,
    required this.imageUrl,
    required this.points,
    required this.isActive,
  });

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      description: json['description'] ?? '',
      experienceYears: json['experienceYears'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      points: List<String>.from(json['points'] ?? []),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'experienceYears': experienceYears,
      'imageUrl': imageUrl,
      'points': points,
      'isActive': isActive,
    };
  }
}

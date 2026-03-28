class AboutUsModel {
  final String id;
  final String title;
  final String description1;
  final String description2;
  final String visionTitle;
  final String visionDescription;
  final String missionTitle;
  final String missionDescription;
  final String imageUrl;
  final bool isActive;

  AboutUsModel({
    required this.id,
    required this.title,
    required this.description1,
    required this.description2,
    required this.visionTitle,
    required this.visionDescription,
    required this.missionTitle,
    required this.missionDescription,
    required this.imageUrl,
    required this.isActive,
  });

  factory AboutUsModel.fromJson(Map<String, dynamic> json) {
    return AboutUsModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description1: json['description1'] ?? '',
      description2: json['description2'] ?? '',
      visionTitle: json['visionTitle'] ?? 'Our Vision',
      visionDescription: json['visionDescription'] ?? '',
      missionTitle: json['missionTitle'] ?? 'Our Mission',
      missionDescription: json['missionDescription'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description1': description1,
      'description2': description2,
      'visionTitle': visionTitle,
      'visionDescription': visionDescription,
      'missionTitle': missionTitle,
      'missionDescription': missionDescription,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }
}

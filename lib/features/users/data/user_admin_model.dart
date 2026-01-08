class UserAdminModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? profileImage;
  final String role;
  final DateTime createdAt;
  final bool isVerified;

  UserAdminModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.profileImage,
    required this.role,
    required this.createdAt,
    required this.isVerified,
  });

  factory UserAdminModel.fromJson(Map<String, dynamic> json) {
    return UserAdminModel(
      id: json['_id'] as String,
      name: json['name'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      role: json['role'] as String? ?? 'user',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}

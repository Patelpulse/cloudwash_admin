class ContactModel {
  final String id;
  final String email;
  final String phone;
  final String address;
  final String businessHours;

  ContactModel({
    required this.id,
    required this.email,
    required this.phone,
    required this.address,
    required this.businessHours,
  });

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      businessHours: json['businessHours'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'phone': phone,
      'address': address,
      'businessHours': businessHours,
    };
  }
}

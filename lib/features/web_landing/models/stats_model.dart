class StatsModel {
  final String id;
  final String happyClients;
  final String totalBranches;
  final String totalCities;
  final String totalOrders;
  final bool isActive;

  StatsModel({
    required this.id,
    required this.happyClients,
    required this.totalBranches,
    required this.totalCities,
    required this.totalOrders,
    required this.isActive,
  });

  factory StatsModel.fromJson(Map<String, dynamic> json) {
    return StatsModel(
      id: json['_id'] ?? '',
      happyClients: json['happyClients'] ?? '',
      totalBranches: json['totalBranches'] ?? '',
      totalCities: json['totalCities'] ?? '',
      totalOrders: json['totalOrders'] ?? '',
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'happyClients': happyClients,
      'totalBranches': totalBranches,
      'totalCities': totalCities,
      'totalOrders': totalOrders,
      'isActive': isActive,
    };
  }
}

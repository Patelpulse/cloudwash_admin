import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_admin/core/config/app_config.dart';
import 'user_admin_model.dart';

class UsersRepository {
  Future<List<UserAdminModel>> getAllUsers() async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.apiUrl}/user/all'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserAdminModel.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<UserAdminModel> getUserById(String id) async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.apiUrl}/user/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserAdminModel.fromJson(data);
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to server: $e');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final response =
          await http.delete(Uri.parse('${AppConfig.apiUrl}/user/$id'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.apiUrl}/orders/user/$userId'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List orders = data['orders'] ?? [];
        double totalSpend = 0;
        for (var order in orders) {
          final summary = order['priceSummary'];
          if (summary != null && summary['total'] != null) {
            totalSpend += (summary['total'] as num).toDouble();
          }
        }
        return {
          'totalOrders': orders.length,
          'totalSpend': totalSpend,
        };
      }
      return {'totalOrders': 0, 'totalSpend': 0.0};
    } catch (e) {
      print('Error fetching stats: $e');
      return {'totalOrders': 0, 'totalSpend': 0.0};
    }
  }
}

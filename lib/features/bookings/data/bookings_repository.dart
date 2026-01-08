import 'dart:convert';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final bookingsRepositoryProvider = Provider((ref) => BookingsRepository());

class BookingsRepository {
  Future<void> updateBookingStatus(String orderId, String status) async {
    final prefs = await SharedPreferences.getInstance();

    // Retrieve token from nested admin_data/token
    String? token;
    final adminDataString = prefs.getString('admin_data');
    if (adminDataString != null) {
      try {
        final adminData = jsonDecode(adminDataString);
        token = adminData['token'];
      } catch (e) {
        print('Error parsing admin_data: $e');
      }
    }

    final response = await http.patch(
      Uri.parse('${AppConfig.apiUrl}/orders/$orderId/status'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update status: ${response.body}');
    }
  }
}

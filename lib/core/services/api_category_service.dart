import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_admin/core/config/app_config.dart';

class ApiCategoryService {
  final String _baseUrl = AppConfig.apiUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final adminDataString = prefs.getString('admin_data');
    if (adminDataString != null) {
      final adminData = json.decode(adminDataString);
      return adminData['token'];
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((cat) => Map<String, dynamic>.from(cat)).toList();
      } else {
        throw Exception('Failed to load categories: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('$_baseUrl/categories/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete category: ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }
}

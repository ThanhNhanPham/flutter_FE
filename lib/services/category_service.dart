import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_url/config.dart';

class CategoryService {
  final String baseUrl = "${Config.apiBaseUrl}/api/Category";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  Future<List<dynamic>> getCategories() async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No authentication token found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      print("Request URL: $baseUrl");
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception("Failed to fetch categories: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getCategories: $e");
      rethrow;
    }
  }

  Future<void> addCategory(Map<String, dynamic> categoryData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No authentication token found. Please log in again.");
      }

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(categoryData),
      );

      print("Request URL: $baseUrl");
      print("Request Body: ${json.encode(categoryData)}");
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode != 201) {
        throw Exception("Failed to add category: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in addCategory: $e");
      rethrow;
    }
  }

  Future<void> updateCategory(int id, Map<String, dynamic> categoryData) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No authentication token found. Please log in again.");
      }

      final response = await http.put(
        Uri.parse("$baseUrl/$id"),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(categoryData),
      );

      print("Request URL: $baseUrl/$id");
      print("Request Body: ${json.encode(categoryData)}");
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode != 204) {
        throw Exception("Failed to update category: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in updateCategory: $e");
      rethrow;
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception("No authentication token found. Please log in again.");
      }

      final response = await http.delete(
        Uri.parse("$baseUrl/$id"),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Request URL: $baseUrl/$id");
      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode != 204) {
        throw Exception("Failed to delete category: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in deleteCategory: $e");
      rethrow;
    }
  }
}

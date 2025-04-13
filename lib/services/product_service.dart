import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_url/config.dart';

class ProductService {
  final String baseUrl = "${Config.apiBaseUrl}/api/Product";

  /// Get JWT token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  /// Build headers for HTTP requests
  Future<Map<String, String>> _buildHeaders() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("No authentication token found. Please log in again.");
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch all products
  Future<List<dynamic>> getProducts() async {
    try {
      final headers = await _buildHeaders();
      final response = await http.get(Uri.parse(baseUrl), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            "Failed to fetch products: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in getProducts: $e");
      rethrow;
    }
  }

  /// Fetch a product by its ID
  Future<Map<String, dynamic>> getProductDetails(int productId) async {
    try {
      final headers = await _buildHeaders();
      final response =
      await http.get(Uri.parse("$baseUrl/$productId"), headers: headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception("Product not found.");
      } else {
        throw Exception(
            "Failed to fetch product details: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getProductDetails: $e");
      rethrow;
    }
  }

  /// Add a new product
  Future<void> addProduct(Map<String, dynamic> productData) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: headers,
        body: json.encode(productData),
      );

      if (response.statusCode != 201) {
        throw Exception(
            "Failed to add product: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in addProduct: $e");
      rethrow;
    }
  }

  /// Update an existing product by ID
  Future<void> updateProduct(int productId, Map<String, dynamic> productData) async {
    try {
      if (!productData.containsKey('categoryId') || productData['categoryId'] == null) {
        throw Exception("categoryId is required in the productData.");
      }

      final headers = await _buildHeaders();
      final response = await http.put(
        Uri.parse("$baseUrl/$productId"),
        headers: headers,
        body: json.encode(productData),
      );

      if (response.statusCode != 204) {
        throw Exception(
            "Failed to update product: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in updateProduct: $e");
      rethrow;
    }
  }

  /// Delete a product by ID
  Future<void> deleteProduct(int productId) async {
    try {
      final headers = await _buildHeaders();
      final response =
      await http.delete(Uri.parse("$baseUrl/$productId"), headers: headers);

      if (response.statusCode != 204) {
        throw Exception(
            "Failed to delete product: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Error in deleteProduct: $e");
      rethrow;
    }
  }

  /// Fetch products by category ID
  Future<List<dynamic>> getProductsByCategory(int categoryId) async {
    try {
      final headers = await _buildHeaders();
      final response = await http.get(
        Uri.parse("$baseUrl/category/$categoryId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception("No products found for this category.");
      } else {
        throw Exception(
            "Failed to fetch products by category: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in getProductsByCategory: $e");
      rethrow;
    }
  }

  /// Fetch product name by ID
  Future<String> getProductName(int productId) async {
    try {
      final productDetails = await getProductDetails(productId);
      return productDetails['productName'] ?? "Unknown Product";
    } catch (e) {
      print("Error in getProductName: $e");
      rethrow;
    }
  }
}

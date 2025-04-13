import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_url/config.dart';

class CartService {
  final String baseUrl = "${Config.apiBaseUrl}/api/Cart";

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("jwt_token");
  }

  Future<List<dynamic>> getCartItems(String userId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data.map((item) {
        return {
          'cartId': item['cartId'],
          'productId': item['productId'],
          'productName': item['productName'],
          'productPrice': item['productPrice'],
          'quantity': item['quantity'],
          'stock': item['stock'], // Thông tin số lượng trong kho
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch cart items.");
    }
  }

  Future<Map<String, dynamic>> addToCart(String userId, int productId, int quantity) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'userId': userId,
        'productId': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      return {
        'cartId': responseData['cartId'], // ID của giỏ hàng
        'productId': responseData['productId'], // ID sản phẩm
        'productName': responseData['productName'], // Tên sản phẩm
        'productPrice': responseData['productPrice'], // Giá sản phẩm
        'quantity': responseData['quantity'], // Số lượng sản phẩm
        'totalPrice': responseData['productPrice'] * responseData['quantity'], // Tổng giá
      };
    } else {
      throw Exception("Failed to add to cart.");
    }
  }

  Future<void> removeFromCart(int cartId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/$cartId"),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 204) {
      throw Exception("Failed to remove item from cart.");
    }
  }

  Future<Map<String, dynamic>> createOrder(List<int> cartIds) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    if (token == null) {
      throw Exception("Authentication token not found. Please log in again.");
    }

    final userId = prefs.getString("user_id");
    if (userId == null) {
      throw Exception("User ID not found. Please log in again.");
    }

    try {
      final url = "${Config.apiBaseUrl}/api/order";
      print("Calling API: $url with UserID: $userId and Cart IDs: $cartIds");

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'userId': userId,
          'cartIds': cartIds,
        }),
      );

      print("Response Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 201) {
        return json.decode(response.body); // Trả về dữ liệu hóa đơn
      } else {
        throw Exception("Failed to create order: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in createOrder: $e");
      rethrow;
    }
  }

  Future<void> updateCartQuantity(int cartId, int newQuantity) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    final response = await http.put(
      Uri.parse("$baseUrl/$cartId"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(newQuantity),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update cart quantity.");
    }
  }

  Future<int> getCartItemCount(String userId) async {
    final url = Uri.parse('${Config.apiBaseUrl}/api/Cart/count?userId=$userId');
    final token = await _getToken();
    if (token == null) {
      throw Exception("Authentication token not found.");
    }

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0; // Trả về số lượng sản phẩm
      } else {
        throw Exception("Failed to fetch cart item count.");
      }
    } catch (e) {
      print("Error in getCartItemCount: $e");
      return 0; // Trả về 0 nếu có lỗi
    }
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_url/config.dart';

class FavoriteService {
  final String baseUrl = "${Config.apiBaseUrl}/api/Favorite";


  // Lấy danh sách sản phẩm yêu thích của người dùng
  Future<List<dynamic>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    final userId = prefs.getString("user_id");

    if (userId == null || token == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(
          "Lỗi khi tải danh sách yêu thích. Status: ${response.statusCode}");
    }
  }

  // Thêm sản phẩm vào danh sách yêu thích
  Future<List<dynamic>> addToFavorite(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");
    final userId = prefs.getString("user_id");

    if (userId == null || token == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }

    final body = {
      "userId": userId,
      "productId": productId,
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      // Trả về danh sách yêu thích mới nhất
      return getFavoritesByUserId(userId);
    } else {
      throw Exception(
          "Lỗi khi thêm vào danh sách yêu thích. Status: ${response.statusCode}");
    }
  }



  // Xóa sản phẩm khỏi danh sách yêu thích
  Future<void> removeFromFavorite(int favoriteId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    if (token == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/$favoriteId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 204) {
      throw Exception(
          "Lỗi khi xóa khỏi danh sách yêu thích. Status: ${response.statusCode}");
    }
  }

  Future<List<dynamic>> getFavoritesByUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token");

    if (token == null) {
      throw Exception("Người dùng chưa đăng nhập.");
    }

    final response = await http.get(
      Uri.parse("$baseUrl/user/$userId"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data is List) {
        return data; // Đảm bảo đây là danh sách
      } else {
        throw Exception("Phản hồi API không phải là danh sách.");
      }
    } else {
      throw Exception(
          "Lỗi khi tải danh sách yêu thích. Status: ${response.statusCode}");
    }
  }

}

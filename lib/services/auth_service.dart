import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config_url/config.dart';

class AuthService {
  // Đăng nhập
  Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse("${Config.apiBaseUrl}/api/Authenticate/login");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      await saveCredentials(data['token'], data['userId'], data['role']);
      return data;
    } else {
      throw Exception("Failed to login: ${response.statusCode}");
    }
  }

  // Lưu thông tin đăng nhập cục bộ
  Future<void> saveCredentials(String token, String userId, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("jwt_token", token);
    await prefs.setString("user_id", userId);
    await prefs.setString("user_role", role);
  }

  // Lấy thông tin đăng nhập từ SharedPreferences
  Future<Map<String, String>> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("jwt_token") ?? '';
    final userId = prefs.getString("user_id") ?? '';
    final role = prefs.getString("user_role") ?? '';
    return {'token': token, 'userId': userId, 'role': role};
  }

  // Đăng ký
  Future<Map<String, dynamic>> register(
      String username,
      String email,
      String password, {
      String? fullName,
      String? role,
      }) async {
    final url = Uri.parse("${Config.apiBaseUrl}/api/Authenticate/register");
    final body = {
      'username': username,
      'email': email,
      'password': password,
    };

    if (fullName != null) body['fullName'] = fullName;
    if (role != null) body['role'] = role;

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to register: ${response.statusCode}");
    }
  }

  // Lấy thông tin chi tiết của User
  Future<Map<String, dynamic>> getUserDetails(String userId, String token) async {
    final url = Uri.parse("${Config.apiBaseUrl}/api/User/$userId");
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to fetch user details: ${response.statusCode}");
    }
  }

  // Cập nhật thông tin User
  Future<void> updateUser(
      String userId, Map<String, dynamic> userData, String token) async {
    final url = Uri.parse("${Config.apiBaseUrl}/api/User/$userId");
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update user: ${response.statusCode}");
    }
  }

  // Cập nhật mật khẩu
  Future<Map<String, dynamic>> updatePassword(
      String userId, String currentPassword, String newPassword) async {
    final url = Uri.parse("${Config.apiBaseUrl}/api/Authenticate/change-password");

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception("Failed to update password: ${response.statusCode}");
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../settings/settings_screen.dart';
import '../update_profile/UpdateAdminScreen.dart';

class ProfileAdminScreen extends StatefulWidget {
  @override
  _ProfileAdminScreenState createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  final AuthService authService = AuthService();
  String? userId;
  String? email;
  String? fullName;
  String? phoneNumber;
  bool isLoading = true;
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkModeProfile') ?? false;
    });
  }

  Future<void> _setThemeMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkModeProfile', value);
    setState(() {
      isDarkMode = value;
    });
  }

  Future<void> _loadUserDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token");
      final userId = prefs.getString("user_id");

      if (token != null && userId != null) {
        final userDetails = await authService.getUserDetails(userId, token);

        setState(() {
          this.userId = userId;
          email = userDetails["email"];
          fullName = userDetails["fullName"];
          phoneNumber = userDetails["phoneNumber"];
          isLoading = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải thông tin người dùng: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _navigateToUpdateUser(BuildContext context) async {
    final updatedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateAdminScreen(
          userId: userId!,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
        ),
      ),
    );

    // Nếu nhận được dữ liệu cập nhật, cập nhật trạng thái
    if (updatedData != null) {
      setState(() {
        email = updatedData['email'];
        fullName = updatedData['fullName'];
        phoneNumber = updatedData['phoneNumber'];
      });
    }
  }


  void _navigateToSettings(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          userId: userId,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
          isDarkMode: isDarkMode,
          onThemeToggle: (value) => _setThemeMode(value),
        ),
      ),
    );
    await _loadThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName ?? "Hồ sơ của Admin",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          email ?? "Email người dùng",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          phoneNumber ?? "Không có số điện thoại",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  // Update Info Button
                  SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      onTap: () => _navigateToUpdateUser(context),
                      leading: Icon(Icons.edit, color: Colors.teal),
                      title: Text(
                        "Cập nhật thông tin",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Settings Button
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: ListTile(
                      onTap: () => _navigateToSettings(context),
                      leading: Icon(Icons.settings, color: Colors.green),
                      title: Text(
                        "Cài đặt",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}

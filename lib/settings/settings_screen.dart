import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screen/login_screen.dart';
import '../update_profile/UpdateUserScreen.dart';

class SettingsScreen extends StatefulWidget {
  final String? userId;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeToggle;

  const SettingsScreen({
    Key? key,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isDarkMode;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode; // Khởi tạo giá trị từ tham số truyền vào
  }

  void _toggleTheme(bool value) {
    setState(() {
      isDarkMode = value; // Cập nhật trạng thái cục bộ
    });
    widget.onThemeToggle(value); // Gọi callback để cập nhật toàn cục (nếu cần)
  }

  void _navigateToUpdateUser() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateUserScreen(
          userId: widget.userId!,
          email: widget.email,
          fullName: widget.fullName,
          phoneNumber: widget.phoneNumber,
        ),
      ),
    );
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    ); // Điều hướng về LoginScreen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cài đặt',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.all(16),
            children: [
              SizedBox(height: 10),
              // Theme Toggle
              ListTile(
                leading: Icon(Icons.brightness_6, color: Colors.green),
                title: Text('Chế độ sáng/tối'),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged: _toggleTheme,
                ),
              ),
              Divider(),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity, // Chiều rộng 100% màn hình
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Màu nền đỏ
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _logout,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.white), // Icon Đăng xuất
                      SizedBox(width: 8), // Khoảng cách giữa icon và text
                      Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

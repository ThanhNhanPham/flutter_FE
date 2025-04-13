import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../settings/settings_screen.dart';
import '../Order/order_history_screen.dart';
import '../update_profile/UpdateUserScreen.dart';
import '../Favorite/favorite_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService authService = AuthService();
  String? userId;
  String? email;
  String? fullName;
  String? phoneNumber;
  bool isLoading = true;
  bool isDarkMode = false;
  List<dynamic> preloadedOrderHistory = [];
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
    _loadThemeMode();
    _preloadOrderHistory();
  }

  Future<void> _preloadOrderHistory() async {
    if (userId != null) {
      try {
        final data = await OrderService().getOrderHistoryByUserId(userId!);
        setState(() {
          preloadedOrderHistory = data;
        });
      } catch (e) {
        print("Không thể tải lịch sử đơn hàng trước: $e");
      }
    }
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
          username = userDetails['userName'];
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
        builder: (context) => UpdateUserScreen(
          userId: userId!,
          email: email,
          fullName: fullName,
          phoneNumber: phoneNumber,
        ),
      ),
    );

    if (updatedData != null && mounted) {
      setState(() {
        email = updatedData['email'];
        fullName = updatedData['fullName'];
        phoneNumber = updatedData['phoneNumber'];
      });
    }
  }

  void _navigateToOrderHistory(BuildContext context) async {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderHistoryScreen(
            userId: userId!,
            preloadedOrderHistory: preloadedOrderHistory,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User ID not found. Please log in.")),
      );
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


  Future<void> _changePassword() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    // Trạng thái hiển thị mật khẩu
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Change Password"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Current Password Field
                  TextField(
                    controller: currentPasswordController,
                    obscureText: !isCurrentPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Current Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isCurrentPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isCurrentPasswordVisible = !isCurrentPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // New Password Field
                  TextField(
                    controller: newPasswordController,
                    obscureText: !isNewPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "New Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isNewPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isNewPasswordVisible = !isNewPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Confirm Password Field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: "Confirm New Password",
                      suffixIcon: IconButton(
                        icon: Icon(
                          isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            isConfirmPasswordVisible = !isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (newPasswordController.text !=
                        confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("New passwords do not match")),
                      );
                      return;
                    }

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getString("user_id") ?? "";

                      if (userId.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "User ID not found. Please log in again.")),
                        );
                        return;
                      }

                      final response = await authService.updatePassword(
                        userId,
                        currentPasswordController.text,
                        newPasswordController.text,
                      );

                      if (response['status'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Password updated successfully")),
                        );
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text("Failed: ${response['message']}")),
                        );
                      }
                    } catch (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${error.toString()}")),
                      );
                    }
                  },
                  child: Text("Update"),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        title: Text(
          'Thông tin cá nhân',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: isDarkMode ? Colors.black : Colors.green,
      ),
      body: Column(
        children: [
          Container(
            color: isDarkMode ? Colors.grey[900] : Colors.green[50],
            child: isLoading
                ? SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
                : Column(
              children: [
                Container(
                  color: isDarkMode ? Colors.grey[740] : Colors.green[50],
                  padding: EdgeInsets.only(
                    top: 30.0,
                    bottom: 10.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToUpdateUser(context),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: isDarkMode
                              ? Colors.grey[700]
                              : Colors.green[100],
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: isDarkMode
                                ? Colors.white
                                : Colors.green[800],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        fullName ?? "Tên người dùng",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                         'MSSV :$username'
                      ),
                      SizedBox(height: 8),
                      Text(
                        email ?? "Email người dùng",
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode
                              ? Colors.grey[400]
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  color: isDarkMode ? Colors.black : Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        "Số điện thoại:",
                        phoneNumber ?? "Không có",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            color: isDarkMode ? Colors.black : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tiện ích',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Column(
            children: [
              OrderHistoryCard(
                onTap: () => _navigateToOrderHistory(context),
                isDarkMode: isDarkMode,
              ),
              SettingsCard(
                onTap: () => _navigateToSettings(context),
                isDarkMode: isDarkMode,
              ),

              ChangePasswordCard( // Thêm mục Đổi mật khẩu
                onTap: _changePassword,
                isDarkMode: isDarkMode,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[800],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.grey[900],
          ),
        ),
      ],
    );
  }
}

class OrderHistoryCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const OrderHistoryCard({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history,
                size: 24,
                color: isDarkMode ? Colors.white : Colors.green[800],
              ),
            ),
            Text(
              'Lịch sử đơn hàng',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const SettingsCard({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.settings,
                size: 24,
                color: isDarkMode ? Colors.white : Colors.green[800],
              ),
            ),
            Text(
              'Cài đặt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const FavoritesCard({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite,
                size: 24,
                color: isDarkMode ? Colors.white : Colors.green[800],
              ),
            ),
            Text(
              'Yêu thích',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChangePasswordCard extends StatelessWidget {
  final VoidCallback onTap;
  final bool isDarkMode;

  const ChangePasswordCard({
    Key? key,
    required this.onTap,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: MediaQuery.of(context).size.width - 16,
        height: 80,
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.5),
              spreadRadius: 2,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[700] : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                size: 24,
                color: isDarkMode ? Colors.white : Colors.green[800],
              ),
            ),
            Text(
              'Đổi mật khẩu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

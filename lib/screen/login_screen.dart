import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/auth_service.dart';
import '../Admin/AdminScreen.dart';
import '../ChangePasswordScreen.dart';
import '../user/UserScreen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService authService = AuthService();
  final LocalAuthentication localAuth = LocalAuthentication();

  bool isLoading = false;
  String savedUsername = '';
  bool isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    checkPasswordChangeStatus();
    loadSavedUsername();
  }
  //Hàm kiểm tra tình trạng Password
  Future<void> checkPasswordChangeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final forcePasswordChange = prefs.getBool("force_password_change") ?? false;

    if (forcePasswordChange) {
      // Điều hướng đến màn hình đổi mật khẩu
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
      );
    }
  }
  Future<void> loadSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedUsername = prefs.getString("saved_username") ?? '';
      if (savedUsername.isNotEmpty) {
        usernameController.text = savedUsername;
      }
    });
  }

  Future<void> saveUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_username", username);
  }

  Future<void> clearSavedUsername() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("saved_username");
    setState(() {
      savedUsername = '';
      usernameController.clear();
    });
  }

  // Future<void> login() async {
  //   setState(() {
  //     isLoading = true;
  //   });

  //   try {
  //     final response = await authService.login(
  //       usernameController.text,
  //       passwordController.text,
  //     );

  //     if (response['status'] == true) {
  //       final prefs = await SharedPreferences.getInstance();

  //       final token = response['token'];
  //       final userId = response['userId'];
  //       final role = response['role'];
  //       final password = passwordController.text;

  //       if (token != null && userId != null && role != null) {
  //         await prefs.setString("jwt_token", token);
  //         await prefs.setString("user_id", userId);
  //         await prefs.setString("user_role", role);
  //         await saveUsername(usernameController.text);

  //         if (password == "Password@123") { // Dùng if để xét tài khoản
  //           // Lưu trạng thái buộc đổi mật khẩu
  //           await prefs.setBool("force_password_change", true);

  //           // Điều hướng đến màn hình đổi mật khẩu
  //           Navigator.pushReplacement(
  //             context,
  //             MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
  //           );
  //         } else {
  //           // Kiểm tra nếu không cần đổi mật khẩu
  //           final forcePasswordChange = prefs.getBool("force_password_change") ?? false;
  //           if (!forcePasswordChange) {
  //             navigateToRoleScreen(role);
  //           } else {
  //             // Hiển thị thông báo nếu cố đăng nhập mà không đổi mật khẩu
  //             ScaffoldMessenger.of(context).showSnackBar(
  //               SnackBar(content: Text("Please change your password first.")),
  //             );
  //           }
  //         }
  //       } else {
  //         throw Exception("Dữ liệu trả về thiếu thông tin");
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Login failed: ${response['message']}")),
  //       );
  //     }
  //   } catch (error) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("Error: ${error.toString()}")),
  //     );
  //   } finally {
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }
  Future<void> login() async {
  final username = usernameController.text.trim();
  final password = passwordController.text;

  if (username.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu.")),
    );
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await authService.login(username, password);

    if (response['status'] == true) {
      final prefs = await SharedPreferences.getInstance();

      final token = response['token'];
      final userId = response['userId'];
      final role = response['role'];

      if (token != null && userId != null && role != null) {
        // ✅ Lưu session
        await prefs.setString("jwt_token", token);
        await prefs.setString("user_id", userId);
        await prefs.setString("user_role", role);
        await prefs.setString("savedUsername", username); // ← Thêm dòng này để dùng cho vân tay

        if (password == "Password@123") {
          await prefs.setBool("force_password_change", true);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ChangePasswordScreen()),
          );
        } else {
          final forcePasswordChange = prefs.getBool("force_password_change") ?? false;
          if (!forcePasswordChange) {
            navigateToRoleScreen(role);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Vui lòng đổi mật khẩu trước khi tiếp tục.")),
            );
          }
        }
      } else {
        throw Exception("Dữ liệu trả về thiếu thông tin");
      }
    } else {
      // ❌ Nếu login fail → xóa token cũ (nếu có)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("jwt_token");
      await prefs.remove("user_id");
      await prefs.remove("user_role");
      await prefs.remove("savedUsername");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thất bại: ${response['message'] ?? 'Lỗi không xác định'}")),
      );
    }
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Lỗi hệ thống: ${error.toString()}")),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}



 Future<void> loginWithFingerprint() async {
  try {
    final isAvailable = await localAuth.canCheckBiometrics;
    if (!isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fingerprint authentication not available.")),
      );
      return;
    }

    final authenticated = await localAuth.authenticate(
      localizedReason: 'Please authenticate to login',
      options: const AuthenticationOptions(biometricOnly: true),
    );

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString("savedUsername") ?? '';
      final role = prefs.getString("user_role") ?? '';

      if (savedUsername.isNotEmpty && role.isNotEmpty) {
        navigateToRoleScreen(role);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("No saved login session. Please login manually.")),
        );
      }
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: ${e.toString()}")),
    );
  }
}

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _launchUrl(String url, String errorMessage) async {
    try {
      final Uri uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception(errorMessage);
      }
    } catch (e) {
      _showSnackBar("Lỗi: $e");
    }
  }

  void navigateToRoleScreen(String role) {
    if (role == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminScreen()),
      );
    } else if (role == 'User') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid role detected.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                  ),

                  SizedBox(height: 70),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (savedUsername.isEmpty) ...[
                          _buildLabel('TÀI KHOẢN'),
                          _buildTextField(
                            controller: usernameController,
                            hintText: 'Nhập tài khoản',
                          ),
                          SizedBox(height: 20),
                        ] else ...[
                          Text(
                            "Logged in as: $savedUsername",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 20),
                        ],
                        _buildLabel('MẬT KHẨU'),
                        _buildPasswordField(),
                        SizedBox(height: 20),
                        if (savedUsername.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: clearSavedUsername,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(0, 50),
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    'Đổi tài khoản',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(height: 20),
                        _buildHelpLink(context),// truyền vào context của widget cha
                        
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: login,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                            'Đăng nhập',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: loginWithFingerprint,
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(double.infinity, 50),
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(
                            'Đăng nhập bằng vân tay',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 110),
                        _buildSocialLinks(),
                        SizedBox(height: 10),
                        _buildFooter()
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(fontSize: 14, color: Colors.grey),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller, required String hintText}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        border: UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: !isPasswordVisible,
      decoration: InputDecoration(
        hintText: 'Nhập mật khẩu',
        suffixIcon: IconButton(
          icon:
          Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
        border: UnderlineInputBorder(),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  Widget _buildHelpLink(BuildContext context) {
  return Center(
    child: RichText(
      text: TextSpan(
        text: 'Đăng nhập không được? ',
        style: const TextStyle(color: Colors.black, fontSize: 14),
        children: [
          TextSpan(
            text: 'Xem hướng dẫn tại đây',
            style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng liên hệ với admin qua SDT 0123456789 để được hỗ trợ. Xin cảm ơn'),
                  ),
                );
              },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildSocialLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.facebook, color: Colors.blue, size: 40),
          onPressed: () => _launchUrl(
            'https://www.facebook.com/utc2hcmc',
            'Không thể mở liên kết Facebook.',
          ),
        ),
        SizedBox(width: 10),
        IconButton(
          icon: Image.asset('assets/images/youtube_logo.webp',
              width: 50, height: 50),
          onPressed: () => _launchUrl(
            'https://www.youtube.com/c/GiaoTh%C3%B4ngV%E1%BA%ADnT%E1%BA%A3iUTC2',
            'Không thể mở liên kết YouTube.',
          ),
        ),
        SizedBox(width: 10),
        IconButton(
          icon: ClipOval(
            child: Image.asset(
              'assets/images/instagram_logo.png',
              width: 40,
              height: 40,
              fit: BoxFit.cover,
            ),
          ),
          onPressed: () => _launchUrl(
            'https://www.instagram.com/utc2.official/?igsh=MWV2ZW5wc21kMmNuZA%3D%3D#',
            'Không thể mở liên kết Instagram.',
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Center(
        child: Text(
          'by- Thành Nhân ©2025 · Phiên bản 3.4.9',
          style: TextStyle(color: Colors.grey, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

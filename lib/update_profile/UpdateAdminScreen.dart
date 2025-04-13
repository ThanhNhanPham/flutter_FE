import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class UpdateAdminScreen extends StatefulWidget {
  final String userId;
  final String? email;
  final String? fullName;
  final String? phoneNumber;

  UpdateAdminScreen({
    required this.userId,
    this.email,
    this.fullName,
    this.phoneNumber,
  });

  @override
  _UpdateAdminScreenState createState() => _UpdateAdminScreenState();
}

class _UpdateAdminScreenState extends State<UpdateAdminScreen> {
  final AuthService authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  String? email;
  String? fullName;
  String? phoneNumber;

  @override
  void initState() {
    super.initState();
    email = widget.email;
    fullName = widget.fullName;
    phoneNumber = widget.phoneNumber;
  }

  Future<void> _updateUser() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("jwt_token");

      if (token != null) {
        try {
          await authService.updateUser(
            widget.userId,
            {
              "email": email,
              "fullName": fullName,
              "phoneNumber": phoneNumber,
            },
            token,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cập nhật thông tin thành công!")),
          );

          Navigator.pop(context, {
            'email': email,
            'fullName': fullName,
            'phoneNumber': phoneNumber,
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Không thể cập nhật thông tin: $e")),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cập nhật thông tin cá nhân",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.green.shade100,
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cập nhật tài khoản",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Chỉnh sửa thông tin cá nhân",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildFormField(
                      initialValue: fullName,
                      label: "Họ và tên",
                      icon: Icons.person,
                      onSaved: (value) => fullName = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập họ và tên";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    _buildFormField(
                      initialValue: email,
                      label: "Email",
                      icon: Icons.email,
                      onSaved: (value) => email = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập email";
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return "Email không hợp lệ";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 12),
                    _buildFormField(
                      initialValue: phoneNumber,
                      label: "Số điện thoại",
                      icon: Icons.phone,
                      onSaved: (value) => phoneNumber = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Vui lòng nhập số điện thoại";
                        }
                        if (!RegExp(r'^(03|05|07|08|09)\d{8}$').hasMatch(value)) {
                          return "Số điện thoại không hợp lệ (VD: 0901234567)";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          vertical: 18,
                          horizontal: 30,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              25), // Điều chỉnh bo góc tại đây
                        ),
                      ),
                      child: Text(
                        "Cập nhật",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFormField({
    required String? initialValue,
    required String label,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green),
        ),
      ),
      onSaved: onSaved,
      validator: validator,
    );
  }
}

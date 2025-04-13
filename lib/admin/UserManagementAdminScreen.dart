import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UserManagementAdminScreen extends StatefulWidget {
  @override
  _UserManagementAdminScreenState createState() =>
      _UserManagementAdminScreenState();
}

class _UserManagementAdminScreenState
    extends State<UserManagementAdminScreen> {
  final UserService userService = UserService();
  List<dynamic> adminUsers = [];
  List<dynamic> regularUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsersForTabs();
  }

  Future<void> _loadUsersForTabs() async {
    try {
      final admins = await userService.getUsersForCurrentTab(true);
      final users = await userService.getUsersForCurrentTab(false);
      setState(() {
        adminUsers = admins;
        regularUsers = users;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải danh sách người dùng: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(BuildContext context, String userId) async {
    try {
      await userService.deleteUser(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xóa người dùng thành công!")),
      );
      _loadUsersForTabs();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể xóa người dùng: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Quản lý người dùng",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Color(0xFF4CAF50), // Màu xanh lá cây
          bottom: TabBar(
            indicatorColor: Colors.white, // Đường gạch dưới màu trắng
            indicatorWeight: 3,
            labelColor: Colors.white, // Màu chữ khi Tab đang được chọn
            unselectedLabelColor: Colors.white60, // Màu chữ khi Tab không được chọn
            tabs: [
              Tab(
                text: "Quản trị viên",
              ),
              Tab(
                text: "Người dùng",
              ),
            ],
          ),
        ),
        body: Container(
          color: Color(0xFFE8F5E9), // Nền nhạt màu xanh lá cây
          child: TabBarView(
            children: [
              // Tab Admin
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : adminUsers.isEmpty
                  ? _buildEmptyState("Không tìm thấy quản trị viên.")
                  : _buildUserList(adminUsers),

              // Tab User
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : regularUsers.isEmpty
                  ? _buildEmptyState("Không tìm thấy người dùng.")
                  : _buildUserList(regularUsers),
            ],
          ),
        ),
      ),
    );
  }

  // Danh sách người dùng
  Widget _buildUserList(List<dynamic> users) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];

        return Dismissible(
          key: Key(user['id'].toString()), // Mỗi item cần có một key duy nhất
          direction: DismissDirection.endToStart, // Vuốt từ phải sang trái
          background: Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerRight,
            color: Colors.redAccent, // Màu nền khi vuốt
            child: Icon(Icons.delete, color: Colors.white), // Biểu tượng xóa
          ),
          onDismissed: (direction) {
            _deleteUser(context, user['id']); // Gọi hàm xóa khi vuốt
          },
          child: Container(
            width: double.infinity, // Chiều ngang 100% màn hình
            margin: EdgeInsets.only(bottom: 12),
            child: Card(
              color: Color(0xFFC8E6C9), // Nền card màu xanh lá nhạt
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user['userName'] ?? "Tên người dùng",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF388E3C), // Màu xanh lá đậm
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Email: ${user['email'] ?? 'Không có email'}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "ID: ${user['id']}",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Trạng thái rỗng
  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
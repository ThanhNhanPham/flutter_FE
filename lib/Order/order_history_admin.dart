import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Order/AdminOrderScreen.dart';
import '../services/order_service.dart';

class OrderHistoryAdminScreen extends StatefulWidget {
  @override
  _OrderHistoryAdminScreenState createState() =>
      _OrderHistoryAdminScreenState();
}

class _OrderHistoryAdminScreenState extends State<OrderHistoryAdminScreen> {
  final OrderService orderService = OrderService();
  List<dynamic> orderHistories = [];
  bool isLoading = true;

  NumberFormat getCurrencyFormat() {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  }

  @override
  void initState() {
    super.initState();
    _loadAllOrderHistories();
  }

  Future<void> _loadAllOrderHistories() async {
    try {
      setState(() {
        isLoading = true;
      });

      final data = await orderService.getAllOrderHistories();

      if (data == null || data.isEmpty) {
        throw Exception("Không có dữ liệu đơn hàng.");
      }

      setState(() {
        orderHistories = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        orderHistories = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải lịch sử đơn hàng: $e")),
      );
    }
  }

  Future<void> _updateOrderStatus(
      BuildContext context, int orderId, String newStatus) async {
    try {
      // Cập nhật trạng thái ngay trên giao diện
      setState(() {
        final orderIndex =
        orderHistories.indexWhere((order) => order['orderId'] == orderId);
        if (orderIndex != -1) {
          orderHistories[orderIndex]['status'] = newStatus;
        }
      });

      // Gọi API để cập nhật trạng thái ở phía server
      await orderService.updateOrderStatus(orderId, newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Trạng thái đơn hàng đã cập nhật thành $newStatus")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể cập nhật trạng thái đơn hàng: $e")),
      );
    }
  }


  void _navigateToOrderScreen(BuildContext context, int orderId) async {
    try {
      final orderData = await orderService.getOrderDetailsById(orderId);

      if (orderData == null) {
        throw Exception("Không tìm thấy chi tiết đơn hàng.");
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminOrderScreen(orderData: orderData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải chi tiết đơn hàng: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lịch sử đơn hàng"),
        backgroundColor: Colors.green[700],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orderHistories.isEmpty
          ? Center(
        child: Text(
          "Không có đơn hàng nào.",
          style: TextStyle(fontSize: 18, color: Colors.grey[600]),
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: orderHistories.length,
        itemBuilder: (context, index) {
          final order = orderHistories[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.0),
              title: Text(
                "Mã đơn hàng: ${order['orderId']} ",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4.0),
                  Text(
                    "Mã khách hàng: ${order['userId']} ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    "Tổng cộng: ${getCurrencyFormat().format(order['totalPrice'] ?? 0)}",
                    style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    "Trạng thái: ${order['status']} ",
                    style: TextStyle(
                      color: order['status'] == "Pending"
                          ? Colors.orange
                          : order['status'] == "Completed"
                          ? Colors.green
                          : Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (order['status'] == "Pending")
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: Icon(Icons.check_circle),
                      label: Text("Hoàn tất"),
                      onPressed: () => _updateOrderStatus(
                          context, order['orderId'], "Completed"),
                    ),
                  if (order['status'] == "Completed")
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      icon: Icon(Icons.delivery_dining),
                      label: Text("Đã giao"),
                      onPressed: () => _updateOrderStatus(
                          context, order['orderId'], "Delivered"),
                    ),
                ],
              ),
              onTap: () =>
                  _navigateToOrderScreen(context, order['orderId']),
            ),
          );
        },
      ),
    );
  }
}

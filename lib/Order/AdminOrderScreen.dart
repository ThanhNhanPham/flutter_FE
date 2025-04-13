import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';


import '../admin/AdminScreen.dart';

class AdminOrderScreen extends StatelessWidget {
  final Map<String, dynamic> orderData;

  const AdminOrderScreen({required this.orderData, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final orderDetails = orderData['orderDetails'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chi tiết hóa đơn (Admin)"),
        backgroundColor: Colors.blue[800],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => AdminScreen()),
                  (route) => false,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mã hóa đơn: ${orderData['orderId'] ?? 'Không xác định'}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tổng tiền: ${orderData['totalPrice'] ?? 0}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Trạng thái: ${orderData['status'] ?? 'Không xác định'}",
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  "Thời gian đặt hàng: ${orderData['orderTime'] ?? 'Không xác định'}",
                  style: const TextStyle(fontSize: 16),
                ),
                const Divider(height: 20, thickness: 1.5),
                const Text(
                  "Chi tiết đơn hàng:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: orderDetails.length,
                    itemBuilder: (context, index) {
                      final detail = orderDetails[index];
                      return ListTile(
                        title: Text(
                          detail['productName'] ?? "Không có tên sản phẩm",
                          style: const TextStyle(fontSize: 16),
                        ),
                        subtitle: Text("Số lượng: ${detail['quantity'] ?? 0}"),
                        trailing: Text("Tạm tính: ${detail['subTotal'] ?? 0}"),
                      );
                    },
                  ),
                ),
                const Divider(height: 20, thickness: 1.5),
                Center(
                  child: Column(
                    children: [
                      if (orderData['status'] != 'Delivered') ...[
                        const Text(
                          "Mã QR cho đơn hàng:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        QrImageView(
                          data: _generateQRCodeData(orderData),
                          version: QrVersions.auto,
                          size: 200.0,
                        ),
                      ] else ...[
                        const Text(
                          "Mã QR không khả dụng vì đơn hàng đã được giao.",
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _generateQRCodeData(Map<String, dynamic> orderData) {
    final buffer = StringBuffer();
    buffer.writeln("Mã hóa đơn: ${orderData['orderId']}");
    buffer.writeln("Tổng tiền: ${orderData['totalPrice']}");
    buffer.writeln("Trạng thái: ${orderData['status']}");
    buffer.writeln("Thời gian đặt hàng: ${orderData['orderTime']}");
    buffer.writeln("Chi tiết đơn hàng:");
    for (var detail in orderData['orderDetails'] ?? []) {
      buffer.writeln("- ${detail['productName']} x${detail['quantity']}: ${detail['subTotal']}");
    }
    return buffer.toString();
  }
}

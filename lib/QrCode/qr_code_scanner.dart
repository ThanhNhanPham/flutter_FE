import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'dart:convert';

import '../Order/AdminOrderScreen.dart';

class QrCodeScanner extends StatefulWidget {
  @override
  _QrCodeScannerState createState() => _QrCodeScannerState();
}

class _QrCodeScannerState extends State<QrCodeScanner> {
  Future<void> scanQrCode(BuildContext context) async {
    try {
      final result = await BarcodeScanner.scan();

      if (result.type == ResultType.Barcode) {
        final scannedData = result.rawContent.trim(); // Lấy toàn bộ nội dung mã QR
        print('Scanned Data: $scannedData');

        // Dữ liệu quét sẽ được điều hướng đến màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminOrderScreen(orderData: _parseScannedData(scannedData)),
          ),
        );
      }
    } catch (e) {
      print('Error occurred while scanning QR Code: $e');
    }
  }

  // Hàm chuyển đổi nội dung quét được thành dữ liệu JSON
  Map<String, dynamic> _parseScannedData(String data) {
    try {
      // Giả định mã QR chứa JSON, cần decode
      return json.decode(data);
    } catch (e) {
      print('Invalid QR Code format: $e');

      // Trường hợp mã QR không phải JSON, xử lý như chuỗi văn bản
      return _parseTextBasedQRCode(data);
    }
  }

  // Hàm phân tích chuỗi văn bản nếu mã QR không phải JSON
  Map<String, dynamic> _parseTextBasedQRCode(String data) {
    final Map<String, dynamic> parsedData = {
      "orderId": null,
      "totalPrice": null,
      "status": null,
      "orderTime": null,
      "orderDetails": []
    };

    try {
      final lines = data.split('\n');
      for (var line in lines) {
        if (line.startsWith("Mã hóa đơn:")) {
          parsedData["orderId"] = int.tryParse(line.split(':').last.trim());
        } else if (line.startsWith("Tổng tiền:")) {
          parsedData["totalPrice"] = double.tryParse(line.split(':').last.trim());
        } else if (line.startsWith("Trạng thái:")) {
          parsedData["status"] = line.split(':').last.trim();
        } else if (line.startsWith("Thời gian đặt hàng:")) {
          parsedData["orderTime"] = line.split(':').last.trim();
        } else if (line.startsWith("-")) {
          final parts = line.substring(1).split('x');
          if (parts.length == 2) {
            parsedData["orderDetails"].add({
              "productName": parts[0].trim(),
              "quantity": int.tryParse(parts[1].split(':').first.trim()),
              "subTotal": double.tryParse(parts[1].split(':').last.trim()),
            });
          }
        }
      }
    } catch (e) {
      print('Failed to parse text-based QR code: $e');
    }

    return parsedData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("QR Code Scanner"),
        backgroundColor: Colors.blue[800],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => scanQrCode(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            "Scan QR Code",
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

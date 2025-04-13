import 'package:flutter/material.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/itransport.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../../config_url/config.dart';
import 'order_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String userId;
  final List<dynamic>? preloadedOrderHistory;

  OrderHistoryScreen({required this.userId, this.preloadedOrderHistory});

  @override
  _OrderHistoryScreenState createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final OrderService orderService = OrderService();
  List<dynamic> orderHistory = [];
  bool isLoading = true;
  late HubConnection _hubConnection;
  final String baseUrl = "${Config.apiBaseUrl}";

  @override
  void initState() {
    super.initState();
    _initializeSignalR();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    if (widget.preloadedOrderHistory != null && widget.preloadedOrderHistory!.isNotEmpty) {
      setState(() {
        orderHistory = widget.preloadedOrderHistory!;
        isLoading = false;
      });
      return;
    }

    try {
      final data = await orderService.getOrderHistoryByUserId(widget.userId);
      setState(() {
        orderHistory = data;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải lịch sử đơn hàng: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _initializeSignalR() async {
    _hubConnection = HubConnectionBuilder()
        .withUrl(
      '$baseUrl/notificationHub',
      options: HttpConnectionOptions(
        transport: HttpTransportType.WebSockets,
        skipNegotiation: true,
      ),
    )
        .withAutomaticReconnect()
        .build();

    _hubConnection.on("OrderStatusUpdated", (arguments) {
      final orderId = arguments?[0];
      final status = arguments?[1];

      print("OrderStatusUpdated: orderId=$orderId, status=$status");

      if (status == "Completed" || status == "Delivered") {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final message = status == "Completed"
              ? "Đơn hàng $orderId đã hoàn thành!"
              : "Đơn hàng $orderId đã được giao!";
          // _showCustomNotification(context, message);
        });
        _loadOrderHistory();
      }
    });

    try {
      await _hubConnection.start();
      print("Kết nối SignalR thành công");
    } catch (error) {
      print("Lỗi kết nối SignalR: $error");
    }
  }

  String formatCurrency(double amount) {
    final NumberFormat currencyFormat =
    NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    return currencyFormat.format(amount);
  }

  String formatOrderDate(String rawDate) {
    final DateTime parsedDate = DateTime.parse(rawDate);
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(parsedDate);
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getTranslatedStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Hoàn thành';
      case 'delivered':
        return 'Đã giao';
      case 'pending':
        return 'Đang xử lý';
      default:
        return 'Không xác định';
    }
  }

  // void _showCustomNotification(BuildContext context, String message) {
  //   final overlay = Overlay.of(context);
  //
  //   late final OverlayEntry overlayEntry;
  //
  //   overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       top: 0,
  //       left: 0,
  //       right: 0,
  //       child: Material(
  //         color: Colors.transparent,
  //         child: Container(
  //           padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.1),
  //                 blurRadius: 10,
  //                 offset: Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           child: SafeArea(
  //             child: Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //               children: [
  //                 Expanded(
  //                   child: Text(
  //                     message,
  //                     style: TextStyle(color: Colors.black, fontSize: 16),
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ),
  //                 IconButton(
  //                   icon: Icon(Icons.close, color: Colors.black),
  //                   onPressed: () {
  //                     overlayEntry.remove();
  //                   },
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  //
  //   overlay.insert(overlayEntry);
  //
  //   Future.delayed(Duration(seconds: 3), () {
  //     overlayEntry.remove();
  //   });
  // }

  void _navigateToOrderScreen(BuildContext context, int orderId) async {
    try {
      final orderData = await orderService.getOrderDetailsById(orderId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(orderData: orderData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải chi tiết đơn hàng: $e")),
      );
    }
  }

  @override
  void dispose() {
    _hubConnection.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lịch sử đơn hàng",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : orderHistory.isEmpty
          ? Center(
        child: Text(
          "Không có đơn hàng nào.",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: orderHistory.length,
          itemBuilder: (context, index) {
            final order = orderHistory[index];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _navigateToOrderScreen(
                  context,
                  order['orderId'],
                ),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Mã đơn hàng: ${order['orderId']}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: getStatusColor(
                                  order['status'] ?? 'unknown')
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              getTranslatedStatus(
                                  order['status'] ?? 'unknown'),
                              style: TextStyle(
                                color: getStatusColor(
                                    order['status'] ?? 'unknown'),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Ngày đặt: ${formatOrderDate(order['orderTime'])}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Tổng cộng: ${formatCurrency(order['totalPrice'] ?? 0)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:signalr_netcore/hub_connection.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'package:signalr_netcore/http_connection_options.dart';
import 'package:signalr_netcore/itransport.dart';
import '../config_url/config.dart';
import '../screen/home_screen.dart';
import '../profile/profile_user_screen.dart';
import '../Favorite/favorite_screen.dart';
import '../../services/auth_service.dart';

class UserScreen extends StatefulWidget {
  @override
  _UserScreenState createState() => _UserScreenState();
}

final String baseUrl = "${Config.apiBaseUrl}";

class _UserScreenState extends State<UserScreen> {
  late HubConnection _hubConnection;
  final AuthService authService = AuthService();
  int _selectedIndex = 0;

  final List<Widget> _pages = [];
  late GlobalKey<FavoriteScreenState> _favoriteScreenKey;
  final GlobalKey<NotificationOverlayState> _notificationKey =
  GlobalKey<NotificationOverlayState>();

  @override
  void initState() {
    super.initState();
    _favoriteScreenKey = GlobalKey<FavoriteScreenState>();
    _pages.addAll([
      HomeScreen(),
      FavoriteScreen(
        key: _favoriteScreenKey,
        onRefreshFavorites: _refreshFavorites,
      ),
      ProfileScreen(),
    ]);
    _initializeSignalR();
  }

  /// Làm mới danh sách yêu thích
  void _refreshFavorites() {
    if (_favoriteScreenKey.currentState != null) {
      _favoriteScreenKey.currentState?.refreshFavorites();
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
        final message = status == "Completed"
            ? "Đơn hàng $orderId đã hoàn thành!"
            : "Đơn hàng $orderId đã được giao!";
        _notificationKey.currentState?.showNotification(message);
      }
    });

    try {
      await _hubConnection.start();
      print("Kết nối SignalR thành công");
    } catch (error) {
      print("Lỗi kết nối SignalR: $error");
    }
  }

  @override
  void dispose() {
    _hubConnection.stop();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
            NotificationOverlay(key: _notificationKey),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          onTap: (int index) async {
            if (index == 1) {
              _favoriteScreenKey.currentState?.refreshFavorites();
            }

            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: "Yêu thích",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: "Tôi",
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationOverlay extends StatefulWidget {
  const NotificationOverlay({Key? key}) : super(key: key);

  @override
  NotificationOverlayState createState() => NotificationOverlayState();
}

class NotificationOverlayState extends State<NotificationOverlay> {
  String? _message;
  bool _visible = false;

  void showNotification(String message) {
    setState(() {
      _message = message;
      _visible = true;
    });

    Future.delayed(Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _visible = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible || _message == null) {
      return SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _message!,
                    style: TextStyle(color: Colors.black, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      _visible = false;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../../services/cart_service.dart';
import '../Order/order_screen.dart';

class CartScreen extends StatefulWidget {
  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService cartService = CartService();
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  List<dynamic> cartItems = [];
  bool isLoading = true;
  double totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bạn chưa đăng nhập.")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final results = await Future.wait([
        cartService.getCartItems(userId),
      ]);

      setState(() {
        cartItems = results[0] ?? [];
        _calculateTotalPrice();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể tải dữ liệu giỏ hàng.")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _calculateTotalPrice() {
    totalPrice = 0.0;
    for (var item in cartItems) {
      final price = item['productPrice'] ?? 0.0;
      final quantity = item['quantity'] ?? 0;
      totalPrice += price * quantity;
    }
    setState(() {});
  }

  void _removeItem(int cartId, int index) async {
    try {
      await cartService.removeFromCart(cartId);
      setState(() {
        cartItems.removeAt(index);
        _calculateTotalPrice();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xóa sản phẩm khỏi giỏ hàng.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể xóa sản phẩm.")),
      );
    }
  }

  void _updateItemQuantity(int cartId, int newQuantity, int stock, int index) async {
    if (newQuantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Số lượng vượt quá kho.")),
      );
      return;
    }

    try {
      await cartService.updateCartQuantity(cartId, newQuantity);
      setState(() {
        cartItems[index]['quantity'] = newQuantity;
        _calculateTotalPrice();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Cập nhật số lượng thành công.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể cập nhật số lượng.")),
      );
    }
  }

  void _createOrder() async {
    try {
      final cartIds = cartItems.map((item) => item['cartId'] as int).toList();

      if (cartIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Giỏ hàng rỗng. Không thể tạo hóa đơn.")),
        );
        return;
      }

      final orderData = await cartService.createOrder(cartIds);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(orderData: orderData),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: Không thể tạo hóa đơn. Vui lòng kiểm tra lại giỏ hàng.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Giỏ hàng của tôi",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
          ? _buildEmptyCart()
          : _buildCartContent(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            "Giỏ hàng trống",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 10),
          Text(
            "Hãy thêm một vài sản phẩm vào giỏ hàng của bạn!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _buildCartItem(item, index);
            },
          ),
        ),
        _buildTotalSection(),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _createOrder,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Ink(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFA726)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Xuất hóa đơn",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCartItem(dynamic item, int index) {
    final price = item['productPrice'] ?? 0.0;
    final quantity = item['quantity'] ?? 0;
    final stock = item['stock'] ?? 0;

    return Dismissible(
      key: ValueKey(item['cartId']),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _removeItem(item['cartId'], index);
      },
      background: Container(
        color: Colors.red,
        padding: EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        child: Icon(
          Icons.delete,
          color: Colors.white,
          size: 30,
        ),
      ),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['productName'] ?? "Tên sản phẩm",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Giá: ${currencyFormat.format(price)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "Số lượng: $quantity",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.remove, color: Colors.blue),
                onPressed: () {
                  if (quantity > 1) {
                    _updateItemQuantity(item['cartId'], quantity - 1, stock, index);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.add, color: Colors.blue),
                onPressed: () {
                  _updateItemQuantity(item['cartId'], quantity + 1, stock, index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      color: Colors.grey[200],
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Tổng cộng: ",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "${currencyFormat.format(totalPrice)}",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

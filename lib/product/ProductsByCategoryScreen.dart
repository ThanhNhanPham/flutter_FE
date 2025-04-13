import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../Cart/cart_screen.dart';
import 'package:intl/intl.dart';

class ProductsByCategoryScreen extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  ProductsByCategoryScreen({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  _ProductsByCategoryScreenState createState() =>
      _ProductsByCategoryScreenState();
}

class _ProductsByCategoryScreenState extends State<ProductsByCategoryScreen> {
  final ProductService productService = ProductService();
  final CartService cartService = CartService();
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');


  List<dynamic> products = [];
  bool isLoading = true;
  int cartItemCount = 0; // Số lượng sản phẩm trong giỏ hàng
  Map<int, int> productQuantities = {}; // Lưu số lượng cho từng sản phẩm

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCartItemCount(); // Lấy số lượng sản phẩm trong giỏ khi khởi tạo
  }

  Future<void> _loadProducts() async {
    try {
      final data = await productService.getProductsByCategory(widget.categoryId);
      setState(() {
        products = data ?? [];
        isLoading = false;

        // Khởi tạo số lượng mặc định là 1 cho mỗi sản phẩm
        productQuantities = {
          for (var product in data) product['productId']: 1,
        };
      });
    } catch (e) {
      print("Error loading products: $e");
      setState(() {
        products = [];
        isLoading = false;
      });
    }
  }

  Future<void> _loadCartItemCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId != null) {
        final count = await cartService.getCartItemCount(userId); // API lấy số lượng
        setState(() {
          cartItemCount = count ?? 0; // Đảm bảo không null
        });
      }
    } catch (e) {
      print("Error loading cart item count: $e");
    }
  }

  void _addToCart(int productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString("user_id");
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Bạn chưa đăng nhập!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final quantity = productQuantities[productId] ?? 1;
      await cartService.addToCart(userId, productId, quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Đã thêm $quantity sản phẩm vào giỏ hàng!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _loadCartItemCount(); // Cập nhật số lượng sản phẩm trong giỏ
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Không thể thêm sản phẩm vào giỏ hàng.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateQuantity(int productId, int change, int stock) {
    setState(() {
      final currentQuantity = productQuantities[productId] ?? 1;
      final newQuantity = currentQuantity + change;

      if (newQuantity > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Số lượng vượt quá kho"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (newQuantity >= 1) {
        productQuantities[productId] = newQuantity;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Sản phẩm: ${widget.categoryName}",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CartScreen()),
                  );
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Colors.green[50],
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : products.isEmpty
            ? Center(
          child: Text(
            "Không có sản phẩm nào.",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        )
            : GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final productId = product['productId'];
            final productName = product['productName'] ?? "Không có tên";
            final price = product['price']?.toString() ?? "0.0";
            final stock = product['stock'] ?? 0;
            final quantity = productQuantities[productId] ?? 1;
            final imageUrl = product['image'] ?? 'https://via.placeholder.com/150';

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Giá: ${currencyFormat.format(product['price'] ?? 0)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove, color: Colors.red),
                              onPressed: () => _updateQuantity(productId, -1, stock),
                            ),
                            Text(
                              '$quantity',
                              style: TextStyle(fontSize: 16),
                            ),
                            IconButton(
                              icon: Icon(Icons.add, color: Colors.green),
                              onPressed: () => _updateQuantity(productId, 1, stock),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ElevatedButton(
                          onPressed: () => _addToCart(productId),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            "Thêm vào giỏ",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),

                ],
              ),
            );
          },

        ),
      ),
    );
  }
}
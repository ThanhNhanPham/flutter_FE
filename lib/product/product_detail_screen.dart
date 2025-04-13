import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Cart/cart_screen.dart';
import '../../services/cart_service.dart';
import '../../services/product_service.dart';
import '../../services/favorite_service.dart';
import 'package:intl/intl.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  ProductDetailScreen({required this.productId});

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService productService = ProductService();
  final CartService cartService = CartService();
  final FavoriteService favoriteService = FavoriteService();
  final NumberFormat currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  Map<String, dynamic>? product;
  bool isLoading = true;
  int quantity = 1; // Số lượng sản phẩm mặc định
  int cartItemCount = 0; // Số lượng sản phẩm trong giỏ hàng
  bool isFavorite = false; // Trạng thái yêu thích

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
    _fetchCartItemCount();
    _checkIfFavorite();
  }

  /// Lấy thông tin chi tiết sản phẩm
  Future<void> _fetchProductDetails() async {
    try {
      final data = await productService.getProductDetails(widget.productId);
      setState(() {
        product = data;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching product details: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Lấy số lượng sản phẩm trong giỏ hàng
  Future<void> _fetchCartItemCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId != null) {
        final count = await cartService.getCartItemCount(userId);
        setState(() {
          cartItemCount = count ?? 0;
        });
      }
    } catch (e) {
      print("Error fetching cart item count: $e");
    }
  }

  /// Kiểm tra trạng thái yêu thích
  Future<void> _checkIfFavorite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString("user_id");

      if (userId != null) {
        final favorites = await favoriteService.getFavorites();
        final isFav =
        favorites.any((item) => item['productId'] == widget.productId);
        setState(() {
          isFavorite = isFav;
        });
      }
    } catch (e) {
      print("Error checking favorite status: $e");
    }
  }

  /// Thêm hoặc xóa khỏi danh sách yêu thích
  Future<void> _toggleFavorite() async {
    try {
      if (isFavorite) {
        // Xóa khỏi danh sách yêu thích
        final favorites = await favoriteService.getFavorites();
        final favoriteItem =
        favorites.firstWhere((item) => item['productId'] == widget.productId);
        await favoriteService.removeFromFavorite(favoriteItem['id']);
        setState(() {
          isFavorite = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã xóa khỏi danh sách yêu thích!")),
        );
      } else {
        // Thêm vào danh sách yêu thích
        await favoriteService.addToFavorite(widget.productId);
        setState(() {
          isFavorite = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Đã thêm vào danh sách yêu thích!")),
        );
      }
    } catch (e) {
      print("Error toggling favorite: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Không thể cập nhật trạng thái yêu thích.")),
      );
    }
  }

  /// Cập nhật số lượng sản phẩm
  void _updateQuantity(int change, int stock) {
    setState(() {
      final newQuantity = quantity + change;
      if (newQuantity > 0 && newQuantity <= stock) {
        quantity = newQuantity;
      } else if (newQuantity > stock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Số lượng vượt quá kho."),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  /// Thêm sản phẩm vào giỏ hàng
  Future<void> _addToCart() async {
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
      await cartService.addToCart(userId, widget.productId, quantity);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Đã thêm $quantity sản phẩm vào giỏ hàng!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      _fetchCartItemCount();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết sản phẩm"),
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
                  ).then((_) {
                    _fetchCartItemCount();
                  });
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : product == null
          ? Center(
        child: Text(
          "Không tìm thấy sản phẩm.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              product?['image'] ?? '',
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Không thể tải ảnh",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                product!['productName'] ?? 'Tên sản phẩm',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Giá: ${currencyFormat.format(product!['price'] ?? 0)}',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Mô tả: ${product!['description'] ?? 'Không có mô tả'}',
                style: TextStyle(fontSize: 16),
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Số lượng:",
                    style: TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: Icon(Icons.remove, color: Colors.red),
                    onPressed: () {
                      _updateQuantity(-1, product!['stock'] ?? 0);
                    },
                  ),
                  Text(
                    '$quantity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add, color: Colors.green),
                    onPressed: () {
                      _updateQuantity(1, product!['stock'] ?? 0);
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                onPressed: _addToCart,
                child: Text(
                  "Thêm vào giỏ hàng",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(
                      horizontal: 30, vertical: 10),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

}

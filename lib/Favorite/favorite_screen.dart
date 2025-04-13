import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/favorite_service.dart';

class FavoriteScreen extends StatefulWidget {
  final VoidCallback? onRefreshFavorites;

  const FavoriteScreen({Key? key, this.onRefreshFavorites}) : super(key: key);

  @override
  FavoriteScreenState createState() => FavoriteScreenState();
}

class FavoriteScreenState extends State<FavoriteScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  late Future<List<dynamic>> _favoriteItems;

  final NumberFormat currencyFormat =
  NumberFormat.currency(locale: 'vi_VN', symbol: '₫');

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  /// Lấy danh sách yêu thích
  Future<List<dynamic>> _fetchUniqueFavorites() async {
    try {
      final favorites = await _favoriteService.getFavorites();
      final Set<int> seenProductIds = {};
      final uniqueFavorites = <dynamic>[];

      for (var item in favorites) {
        final productId = item['productId'];
        if (!seenProductIds.contains(productId)) {
          seenProductIds.add(productId);
          uniqueFavorites.add(item);
        }
      }
      return uniqueFavorites;
    } catch (e) {
      print("Error fetching favorites: $e");
      return [];
    }
  }

  /// Làm mới danh sách yêu thích
  void refreshFavorites() {
    setState(() {
      _favoriteItems = _fetchUniqueFavorites();
    });
  }

  void _fetchFavorites() {
    setState(() {
      _favoriteItems = _fetchUniqueFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Danh sách yêu thích",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: Colors.pinkAccent,
        elevation: 0,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _favoriteItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Danh sách yêu thích trống."));
          } else {
            final favorites = snapshot.data!;
            return ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return Card(
                  margin:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        // Hình ảnh sản phẩm
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item['productImage'] != null
                              ? Image.network(
                            item['productImage'],
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          )
                              : Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Chi tiết sản phẩm
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['productName'] ?? "Không có tên",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Giá: ${currencyFormat.format(item['productPrice'] ?? 0)}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Mã sản phẩm: ${item['productId'] ?? "N/A"}",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/product_service.dart';
import '../../services/category_service.dart';

class ProductScreen extends StatefulWidget {
  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final ProductService productService = ProductService();
  final CategoryService categoryService = CategoryService();

  List<dynamic> products = [];
  List<dynamic> categories = [];
  String? userRole;

  NumberFormat getCurrencyFormat() {
    return NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadCategories();
    _loadUserRole();
  }

  Future<void> _loadProducts() async {
    try {
      final data = await productService.getProducts();
      setState(() {
        products = data;
      });
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  Future<void> _loadCategories() async {
    try {
      final data = await categoryService.getCategories();
      setState(() {
        categories = data;
      });
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userRole = prefs.getString("user_role");
    });
  }

  void _showProductDialog({dynamic product}) {
    final TextEditingController nameController =
    TextEditingController(text: product?['productName'] ?? '');
    final TextEditingController priceController =
    TextEditingController(text: product?['price']?.toString() ?? '');
    final TextEditingController descriptionController =
    TextEditingController(text: product?['description'] ?? '');
    final TextEditingController stockController =
    TextEditingController(text: product?['stock']?.toString() ?? '');
    final TextEditingController imageController =
    TextEditingController(text: product?['image'] ?? '');
    int? selectedCategoryId = product?['categoryId'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(product == null ? "Thêm sản phẩm" : "Chỉnh sửa sản phẩm"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Tên sản phẩm"),
                ),
                TextField(
                  controller: priceController,
                  decoration: InputDecoration(labelText: "Giá"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(labelText: "Mô tả"),
                ),
                TextField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: "Tồn kho"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: imageController,
                  decoration: InputDecoration(labelText: "URL hình ảnh"),
                ),
                DropdownButtonFormField<int>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(labelText: "Chọn danh mục"),
                  items: categories
                      .map<DropdownMenuItem<int>>(
                        (category) => DropdownMenuItem<int>(
                      value: category['categoryId'],
                      child: Text(category['categoryName']),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Hủy"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Vui lòng chọn danh mục")),
                  );
                  return;
                }

                final newProduct = {
                  'productName': nameController.text,
                  'price': double.parse(priceController.text),
                  'description': descriptionController.text,
                  'image': imageController.text,
                  'stock': int.parse(stockController.text),
                  'categoryId': selectedCategoryId,
                };

                try {
                  if (product == null) {
                    await productService.addProduct(newProduct);
                  } else {
                    await productService.updateProduct(
                        product['productId'], newProduct);
                  }
                  _loadProducts();
                  Navigator.pop(context);
                } catch (e) {
                  print("Error saving product: $e");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi lưu sản phẩm: $e")),
                  );
                }
              },
              child: Text(product == null ? "Thêm" : "Lưu"),
            ),
          ],
        );
      },
    );
  }

  void _deleteProduct(int productId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận xóa"),
        content: Text("Bạn có chắc chắn muốn xóa sản phẩm này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Xóa"),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await productService.deleteProduct(productId);
        _loadProducts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xóa sản phẩm thành công")),
        );
      } catch (e) {
        print("Error deleting product: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi xóa sản phẩm: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý sản phẩm"),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(8),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            elevation: 4,
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  product['image'],
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.image, size: 50, color: Colors.grey);
                  },
                ),
              ),
              title: Text(
                product['productName'],
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giá: ${getCurrencyFormat().format(product['price'] ?? 0)}',
                    style: TextStyle(color: Colors.green),
                  ),
                  Text(
                    'Tồn kho: ${product['stock']}',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showProductDialog(product: product);
                  } else if (value == 'delete') {
                    _deleteProduct(product['productId']);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit, color: Colors.blue),
                      title: Text("Sửa sản phẩm"),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text("Xóa sản phẩm"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: userRole == 'Admin' || userRole == 'admin'
          ? FloatingActionButton(
        onPressed: () => _showProductDialog(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}

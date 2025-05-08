import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/category_service.dart';
import '../Product/ProductsByCategoryScreen.dart';

class CategoryManagementScreen extends StatefulWidget {
  @override
  _CategoryManagementScreenState createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final CategoryService categoryService = CategoryService();
  List<dynamic> categories = [];
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadUserRole();
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

  void _showCategoryDialog({dynamic category}) {
    final TextEditingController nameController =
    TextEditingController(text: category?['categoryName'] ?? '');
    final TextEditingController descriptionController =
    TextEditingController(text: category?['description'] ?? '');

    showDialog(
        context: context,
        builder: (context) {
      return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            category == null ? "Add Category" : "Edit Category",
            style: TextStyle(color: Colors.teal),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Category Name",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
          TextButton(
          onPressed: () => Navigator.pop(context),
    child: Text("Cancel"),
    ),
    ElevatedButton(
    style: ElevatedButton.styleFrom(
    backgroundColor: Colors.teal,
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(10),
    ),
    ),
    onPressed: ()
    async {
      final newCategory = {
        'categoryName': nameController.text,
        'description': descriptionController.text,
      };

      try {
        if (category == null) {
          await categoryService.addCategory(newCategory);
        } else {
          await categoryService.updateCategory(
              category['categoryId'], newCategory);
        }
        Navigator.pop(context);
        _loadCategories();
      } catch (e) {
        print("Error saving category: $e");
      }
    },
      child: Text(category == null ? "Add" : "Save"),
    ),
          ],
      );
        },
    );
  }

  void _deleteCategory(int categoryId) async {
    try {
      await categoryService.deleteCategory(categoryId);
      _loadCategories();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  void _navigateToProducts(int categoryId, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsByCategoryScreen(
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Quản lý danh mục"),
        backgroundColor: Colors.green, // AppBar màu xanh lá cây
        centerTitle: true,
        elevation: 5,
      ),
      body: categories.isEmpty
          ? Center(
        child: CircularProgressIndicator(
          color: Colors.teal,
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              elevation: 8,
              margin: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(
                    vertical: 10, horizontal: 20),
                onTap: () => _navigateToProducts(
                    category['categoryId'], category['categoryName']),
                title: Text(
                  category['categoryName'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    category['description'],
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ),
                trailing: userRole == 'Admin'
                    ? PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showCategoryDialog(category: category);
                    } else if (value == 'delete') {
                      _deleteCategory(category['categoryId']);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(Icons.more_vert),
                )
                    : null,
              ),
            );
          },
        ),
      ),
      floatingActionButton: userRole == 'Admin'
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showCategoryDialog(),
        child: Icon(Icons.add),
      )
          : null,
    );
  }
}

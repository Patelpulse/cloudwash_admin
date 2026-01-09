import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/features/categories/widgets/category_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _firebaseService = FirebaseCategoryService();

  Future<void> _deleteCategory(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firebase
        await _firebaseService.deleteCategory(firebaseId);

        // TODO: Also delete from MongoDB backend if needed
        // if (mongoId != null) {
        //   await http.delete(Uri.parse('$apiUrl/categories/$mongoId'));
        // }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryBlue,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Firebase',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.refresh, size: 20, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text('Auto-refresh',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              await context.push('/categories/add');
            },
            icon: const Icon(
              Icons.add,
              size: 18,
              color: Colors.white,
            ),
            label: const Text('Add Main Category',
                style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryStream(context),
        ],
      ),
    );
  }

  Widget _buildCategoryStream(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {}); // Rebuild to retry
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final categories = snapshot.data ?? [];

        if (categories.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.category_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No categories found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first category to get started',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return _buildCategoryGrid(context, categories);
      },
    );
  }

  Widget _buildCategoryGrid(
      BuildContext context, List<Map<String, dynamic>> categories) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive Grid
        int crossAxisCount = 4;
        double childAspectRatio = 0.8; // Vertical cards

        if (width < 600) {
          crossAxisCount = 1;
          childAspectRatio = 1.2;
        } else if (width < 900) {
          crossAxisCount = 2;
          childAspectRatio = 0.9;
        } else if (width < 1200) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return CategoryCard(
              title: cat['name'] ?? 'Untitled',
              description: cat['description'] ?? 'No description',
              price: cat['price'] != null ? '₹${cat['price']}' : '₹0',
              status: cat['isActive'] == true ? 'Active' : 'Inactive',
              imageUrl: cat['imageUrl'],
              placeholderColor: Colors.grey.shade200,
              onEdit: () async {
                // Pass both Firebase ID and data
                final editData = {
                  ...cat,
                  'firebaseId': cat['id'], // Firebase ID
                };
                await context.push('/categories/add', extra: editData);
              },
              onDelete: () => _deleteCategory(cat['id'], cat['mongoId']),
              onViewSubCategories: () =>
                  context.go('/sub-categories', extra: cat['name']),
            );
          },
        );
      },
    );
  }
}

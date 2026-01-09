import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_subcategory_service.dart';
import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/features/sub_categories/widgets/sub_category_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SubCategoriesScreen extends StatefulWidget {
  final String? initialCategoryFilter;
  const SubCategoriesScreen({super.key, this.initialCategoryFilter});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  final _firebaseService = FirebaseSubCategoryService();
  final _categoryService = FirebaseCategoryService();
  String _selectedCategoryFilter = 'All Categories';
  Map<String, String> _categoryMap = {}; // id -> name

  @override
  void initState() {
    super.initState();
    if (widget.initialCategoryFilter != null) {
      _selectedCategoryFilter = widget.initialCategoryFilter!;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    // Load categories for filter dropdown
    _categoryService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categoryMap = {for (var cat in categories) cat['id']: cat['name']};
        });
      }
    });
  }

  Future<void> _deleteSubCategory(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub-Category'),
        content: const Text(
            'Are you sure you want to delete this sub-category? This action cannot be undone.'),
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
        await _firebaseService.deleteSubCategory(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sub-category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting: $e'),
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
                'Sub Categories',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
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
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/sub-categories/add');
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Sub Category',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 24),
          _buildSubCategoryStream(),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    List<String> categoryNames = ['All Categories', ..._categoryMap.values];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: Colors.grey),
          const SizedBox(width: 12),
          const Text('Parent Category:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: categoryNames.contains(_selectedCategoryFilter)
                    ? _selectedCategoryFilter
                    : 'All Categories',
                isExpanded: true,
                items: categoryNames
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedCategoryFilter = v!;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubCategoryStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getSubCategories(),
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
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        var subCategories = snapshot.data ?? [];

        // Apply filter
        if (_selectedCategoryFilter != 'All Categories') {
          final categoryId = _categoryMap.entries
              .firstWhere((e) => e.value == _selectedCategoryFilter,
                  orElse: () => const MapEntry('', ''))
              .key;
          if (categoryId.isNotEmpty) {
            subCategories = subCategories
                .where((sub) => sub['categoryId'] == categoryId)
                .toList();
          }
        }

        if (subCategories.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.category_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No sub-categories found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return _buildGrid(context, subCategories);
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        double childAspectRatio = 0.9;

        if (width < 1400) crossAxisCount = 3;
        if (width < 1000) crossAxisCount = 2;
        if (width < 600) {
          crossAxisCount = 1;
          childAspectRatio = 1.2;
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final parentName = _categoryMap[item['categoryId']] ?? 'Unknown';

            return SubCategoryCard(
              title: item['name'] ?? 'No Name',
              parentCategory: parentName,
              servicesCount: '0', // Can be calculated
              isActive: item['isActive'] == true,
              imageUrl: item['imageUrl'],
              placeholderColor: Colors.blue.shade100,
              onEdit: () async {
                final editData = {
                  ...item,
                  'firebaseId': item['id'],
                };
                await context.push('/sub-categories/add', extra: editData);
              },
              onDelete: () => _deleteSubCategory(item['id'], item['mongoId']),
            );
          },
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/sub_categories/widgets/sub_category_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SubCategoriesScreen extends StatefulWidget {
  const SubCategoriesScreen({super.key});

  @override
  State<SubCategoriesScreen> createState() => _SubCategoriesScreenState();
}

class _SubCategoriesScreenState extends State<SubCategoriesScreen> {
  List<dynamic> _subCategories = [];
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _selectedCategoryFilter = 'All Categories';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';

      // Fetch Sub Categories
      final subResponse = await http.get(Uri.parse('$baseUrl/sub-categories'));

      // Fetch Categories for filter
      final catResponse = await http.get(Uri.parse('$baseUrl/categories'));

      if (subResponse.statusCode == 200 && catResponse.statusCode == 200) {
        if (mounted) {
          setState(() {
            _subCategories = json.decode(subResponse.body);
            _categories = json.decode(catResponse.body);
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _deleteSubCategory(String id) async {
    bool confirm = await showDialog(
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
        ) ??
        false;

    if (!confirm) return;

    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
      final response =
          await http.delete(Uri.parse('$baseUrl/sub-categories/$id'));

      if (response.statusCode == 200) {
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sub-Category deleted successfully')),
          );
        }
      } else {
        throw Exception('Failed to delete');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting sub-category: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredSubCategories = _selectedCategoryFilter == 'All Categories'
        ? _subCategories
        : _subCategories.where((sub) {
            final catName =
                sub['category'] is Map ? sub['category']['name'] : '';
            return catName == _selectedCategoryFilter;
          }).toList();

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
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/sub-categories/add');
                  _fetchData();
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Sub Category',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildFilterBar(),
          const SizedBox(height: 24),
          filteredSubCategories.isEmpty
              ? const Center(child: Text('No sub-categories found'))
              : _buildGrid(context, filteredSubCategories),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    // Extract unique category names for dropdown
    List<String> categoryNames = ['All Categories'];
    categoryNames.addAll(_categories.map((c) => c['name'].toString()));

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

  Widget _buildGrid(BuildContext context, List<dynamic> items) {
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
            // Access parent name safely. 'category' might be populated or an ID string.
            // Based on controller, it is populated with 'name'.
            final parentName =
                item['category'] is Map ? item['category']['name'] : 'Unknown';

            return SubCategoryCard(
              title: item['name'] ?? 'No Name',
              parentCategory: parentName,
              servicesCount: '0', // Placeholder or add logic if needed
              isActive: item['isActive'] == true,
              imageUrl: item['imageUrl'],
              placeholderColor: Colors.blue.shade100, // Or dynamic color
              onEdit: () async {
                await context.push('/sub-categories/add', extra: item);
                _fetchData();
              },
              onDelete: () => _deleteSubCategory(item['_id']),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_service_service.dart';
import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/features/services/widgets/service_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _firebaseService = FirebaseServiceService();
  final _categoryService = FirebaseCategoryService();

  String _selectedCategoryFilter = 'All Categories';
  final Set<String> _selectedServiceIds = {};
  Map<String, String> _categoryMap = {}; // id -> name

  @override
  void initState() {
    super.initState();
    _loadRelatedData();
  }

  Future<void> _loadRelatedData() async {
    // Load categories and sub-categories for display
    _categoryService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categoryMap = {for (var cat in categories) cat['id']: cat['name']};
        });
      }
    });
  }

  Future<void> _deleteService(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseService.deleteService(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Service deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _toggleSelectAll(bool? selected, List<Map<String, dynamic>> services) {
    setState(() {
      if (selected == true) {
        _selectedServiceIds.addAll(services.map((s) => s['id'] as String));
      } else {
        _selectedServiceIds.clear();
      }
    });
  }

  void _onServiceSelected(String id, bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedServiceIds.add(id);
      } else {
        _selectedServiceIds.remove(id);
      }
    });
  }

  Future<void> _bulkDelete() async {
    final count = _selectedServiceIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Bulk Delete'),
        content:
            Text('Are you sure you want to delete $count selected services?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Delete All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        for (var id in _selectedServiceIds) {
          await _firebaseService.deleteService(id);
        }

        setState(() {
          _selectedServiceIds.clear();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$count services deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
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
                'Services Management',
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
                  if (_selectedServiceIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: ElevatedButton.icon(
                        onPressed: _bulkDelete,
                        icon: const Icon(Icons.delete_sweep,
                            size: 18, color: Colors.white),
                        label: Text(
                            'Delete Selected (${_selectedServiceIds.length})',
                            style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/services/add');
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add New Service',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildServicesStream(),
        ],
      ),
    );
  }

  Widget _buildServicesStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseService.getServices(),
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

        var services = snapshot.data ?? [];

        // Apply filter
        if (_selectedCategoryFilter != 'All Categories') {
          final categoryId = _categoryMap.entries
              .firstWhere((e) => e.value == _selectedCategoryFilter,
                  orElse: () => const MapEntry('', ''))
              .key;
          if (categoryId.isNotEmpty) {
            services = services
                .where((service) => service['categoryId'] == categoryId)
                .toList();
          }
        }

        if (services.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.design_services_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No services found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildFilters(services),
            const SizedBox(height: 24),
            _buildServicesGrid(context, services),
          ],
        );
      },
    );
  }

  Widget _buildFilters(List<Map<String, dynamic>> services) {
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
          const Text('Filter by Category:',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 30,
              width: 1,
              color: Colors.grey.shade300,
            ),
          ),
          Checkbox(
            value: _selectedServiceIds.length == services.length &&
                services.isNotEmpty,
            onChanged: (v) => _toggleSelectAll(v, services),
            activeColor: AppTheme.primaryBlue,
          ),
          const Text('Select All',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(
      BuildContext context, List<Map<String, dynamic>> services) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        double childAspectRatio = 1.2;

        if (width < 1200) {
          crossAxisCount = 2;
        }
        if (width < 700) {
          crossAxisCount = 1;
          childAspectRatio = 1.1;
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
          itemCount: services.length,
          itemBuilder: (context, index) {
            final s = services[index];
            final categoryName =
                _categoryMap[s['categoryId']] ?? 'Uncategorized';

            return ServiceCard(
              title: s['name'] ?? 'No Name',
              description: s['description'] ?? '',
              price: '₹${s['price']}',
              category: categoryName,
              isActive: s['isActive'] == true,
              imageUrl: s['imageUrl'],
              placeholderColor: Colors.blue.shade100,
              isSelected: _selectedServiceIds.contains(s['id']),
              onSelectChanged: (v) => _onServiceSelected(s['id'], v),
              onEdit: () async {
                final editData = {
                  ...s,
                  'firebaseId': s['id'],
                };
                await context.push('/services/add', extra: editData);
              },
              onDelete: () => _deleteService(s['id'], s['mongoId']),
            );
          },
        );
      },
    );
  }
}

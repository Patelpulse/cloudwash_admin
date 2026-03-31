import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/core/services/firebase_subcategory_service.dart';
import 'package:flutter/material.dart';

class ReorderSubCategoriesScreen extends StatefulWidget {
  final String? initialCategoryId;

  const ReorderSubCategoriesScreen({super.key, this.initialCategoryId});

  @override
  State<ReorderSubCategoriesScreen> createState() =>
      _ReorderSubCategoriesScreenState();
}

class _ReorderSubCategoriesScreenState
    extends State<ReorderSubCategoriesScreen> {
  final _subService = FirebaseSubCategoryService();
  final _categoryService = FirebaseCategoryService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _selectedCategoryId;
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final subs = await _subService.getSubCategories().first;
    final cats = await _categoryService.getCategories().first;

    subs.sort((a, b) {
      final aOrder = (a['displayOrder'] ?? 100000) as num;
      final bOrder = (b['displayOrder'] ?? 100000) as num;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
    });

    cats.sort((a, b) => (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString()));

    if (!mounted) return;
    setState(() {
      _subCategories = List<Map<String, dynamic>>.from(subs);
      _categories = List<Map<String, dynamic>>.from(cats);
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _visibleSubs {
    if (_selectedCategoryId == null) return _subCategories;
    return _subCategories
        .where((s) =>
            s['categoryId'] == _selectedCategoryId ||
            s['category'] == _selectedCategoryId)
        .toList();
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    try {
      await _subService.updateDisplayOrders(_visibleSubs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sub-category order updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save order: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleSubs = _visibleSubs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder Sub-Categories'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveOrder,
            icon: _isSaving
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('Filter by category:'),
                      const SizedBox(width: 12),
                      DropdownButton<String?>(
                        value: _selectedCategoryId,
                        hint: const Text('All'),
                        onChanged: (value) => setState(() {
                          _selectedCategoryId = value;
                        }),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All categories'),
                          ),
                          ..._categories.map(
                            (cat) => DropdownMenuItem(
                              value: cat['id'] as String,
                              child: Text(cat['name'] ?? 'Category'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: visibleSubs.isEmpty
                        ? const Center(child: Text('No sub-categories'))
                        : ReorderableListView.builder(
                            itemCount: visibleSubs.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex -= 1;
                              final mutableList = List<Map<String, dynamic>>.from(visibleSubs);
                              final item = mutableList.removeAt(oldIndex);
                              mutableList.insert(newIndex, item);

                              // Write back into master list while preserving others
                              setState(() {
                                // Remove items belonging to filter from master
                                _subCategories.removeWhere((s) =>
                                    (_selectedCategoryId == null) ||
                                    s['categoryId'] == _selectedCategoryId ||
                                    s['category'] == _selectedCategoryId);
                                // Insert reordered items at start of list then append untouched
                                _subCategories.insertAll(0, mutableList);
                              });
                            },
                            buildDefaultDragHandles: false,
                            itemBuilder: (context, index) {
                              final sub = visibleSubs[index];
                              final categoryMap = _categories.firstWhere(
                                (c) =>
                                    c['id'] == sub['categoryId'] ||
                                    c['id'] == sub['category'],
                                orElse: () => <String, dynamic>{},
                              );
                              final categoryName =
                                  (categoryMap['name'] ?? '').toString();
                              return Card(
                                key: ValueKey(sub['id']),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle),
                                  ),
                                  title: Text(sub['name'] ?? 'Untitled'),
                                  subtitle: Text(
                                    '${categoryName.isNotEmpty ? '$categoryName • ' : ''}Position ${index + 1}',
                                  ),
                                  trailing: Text(
                                    '₹${sub['price'] ?? '--'}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}

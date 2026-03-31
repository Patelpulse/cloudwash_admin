import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:flutter/material.dart';

class ReorderCategoriesScreen extends StatefulWidget {
  const ReorderCategoriesScreen({super.key});

  @override
  State<ReorderCategoriesScreen> createState() =>
      _ReorderCategoriesScreenState();
}

class _ReorderCategoriesScreenState extends State<ReorderCategoriesScreen> {
  final _firebaseService = FirebaseCategoryService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final data = await _firebaseService.getCategories().first;
    data.sort((a, b) {
      final aOrder = (a['displayOrder'] ?? 100000) as num;
      final bOrder = (b['displayOrder'] ?? 100000) as num;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return (a['name'] ?? '').toString().compareTo((b['name'] ?? '').toString());
    });
    if (!mounted) return;
    setState(() {
      _categories = List<Map<String, dynamic>>.from(data);
      _isLoading = false;
    });
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    try {
      await _firebaseService.updateDisplayOrders(_categories);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category order updated')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reorder Categories'),
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
          : _categories.isEmpty
              ? const Center(child: Text('No categories to reorder'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ReorderableListView.builder(
                    itemCount: _categories.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _categories.removeAt(oldIndex);
                        _categories.insert(newIndex, item);
                      });
                    },
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        key: ValueKey(category['id']),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(category['name'] ?? 'Untitled'),
                          subtitle:
                              Text('Position ${index + 1} • ${category['description'] ?? ''}'),
                          trailing: Text(
                            '₹${category['price'] ?? '--'}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

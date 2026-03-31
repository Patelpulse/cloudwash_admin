import 'package:cloud_admin/core/services/firebase_service_service.dart';
import 'package:flutter/material.dart';

class ReorderServicesScreen extends StatefulWidget {
  const ReorderServicesScreen({super.key});

  @override
  State<ReorderServicesScreen> createState() => _ReorderServicesScreenState();
}

class _ReorderServicesScreenState extends State<ReorderServicesScreen> {
  final _firebaseService = FirebaseServiceService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final data = await _firebaseService.getServices().first;
      data.sort((a, b) {
        final aOrder = (a['displayOrder'] ?? 100000) as num;
        final bOrder = (b['displayOrder'] ?? 100000) as num;
        if (aOrder == bOrder) {
          final aCreated = a['createdAt'];
          final bCreated = b['createdAt'];
          return '$aCreated'.compareTo('$bCreated');
        }
        return aOrder.compareTo(bOrder);
      });
      if (!mounted) return;
      setState(() {
        _services = List<Map<String, dynamic>>.from(data);
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveOrder() async {
    setState(() => _isSaving = true);
    try {
      await _firebaseService.updateDisplayOrders(_services);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service order updated')),
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
        title: const Text('Reorder Services'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveOrder,
            icon: _isSaving
                ? const SizedBox(
                    height: 14,
                    width: 14,
                    child:
                        CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _services.isEmpty
              ? const Center(child: Text('No services to reorder'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: ReorderableListView.builder(
                    itemCount: _services.length,
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _services.removeAt(oldIndex);
                        _services.insert(newIndex, item);
                      });
                    },
                    buildDefaultDragHandles: false,
                    itemBuilder: (context, index) {
                      final service = _services[index];
                      return Card(
                        key: ValueKey(service['id']),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: ReorderableDragStartListener(
                            index: index,
                            child: const Icon(Icons.drag_handle),
                          ),
                          title: Text(service['name'] ?? 'Untitled'),
                          subtitle: Text(
                            'Position ${index + 1} · ${service['categoryId'] ?? 'No category'}',
                          ),
                          trailing: Text(
                            '₹${service['price'] ?? '--'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

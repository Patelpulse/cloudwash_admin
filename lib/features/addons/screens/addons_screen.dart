import 'package:cloud_admin/core/services/firebase_addon_service.dart';
import 'package:cloud_admin/features/addons/widgets/addon_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddonsScreen extends StatefulWidget {
  const AddonsScreen({super.key});

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  final _firebaseAddonService = FirebaseAddonService();

  Future<void> _deleteAddon(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this add-on?'),
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
        await _firebaseAddonService.deleteAddon(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add-on deleted successfully'),
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
                'Service Add-ons',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
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
            ],
          ),
          const SizedBox(height: 16),
          // Orange Header/Button Bar
          InkWell(
            onTap: () async {
              await context.push('/addons/add');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEA8C00), // Orange color
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'New Add-on',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'All Add-ons',
            style: TextStyle(
              color: Color(0xFFF59E0B), // Orange/Amber
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(thickness: 1, color: Color(0xFFFFF7ED)),
          const SizedBox(height: 16),
          _buildAddonsStream(),
        ],
      ),
    );
  }

  Widget _buildAddonsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseAddonService.getAddons(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFEA8C00)),
              ),
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

        final addons = snapshot.data ?? [];

        if (addons.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.extension_outlined,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No add-ons found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "New Add-on" to create one',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildGrid(context, addons);
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<Map<String, dynamic>> addons) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 2.5; // Wider horizontal cards

        if (width < 900) {
          crossAxisCount = 1;
          childAspectRatio = 2.8;
          if (width < 600) childAspectRatio = 1.8;
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
          itemCount: addons.length,
          itemBuilder: (context, index) {
            final addon = addons[index];

            return AddonCard(
              title: addon['name'] ?? 'No Name',
              description: addon['description'] ?? '',
              price: '₹${addon['price'] ?? 0}',
              duration: '', // Not stored in addons
              imageUrl: addon['imageUrl'],
              category: null, // Not linked to category in current structure
              subCategory: null,
              placeholderColor: Colors.grey.shade800,
              onEdit: () async {
                final editData = {
                  ...addon,
                  'firebaseId': addon['id'],
                };
                await context.push('/addons/add', extra: editData);
              },
              onDelete: () => _deleteAddon(addon['id'], addon['mongoId']),
            );
          },
        );
      },
    );
  }
}

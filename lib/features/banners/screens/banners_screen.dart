import 'package:cloud_admin/core/services/firebase_banner_service.dart';
import 'package:cloud_admin/features/banners/widgets/banner_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final _firebaseBannerService = FirebaseBannerService();

  Future<void> _deleteBanner(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this banner?'),
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
        await _firebaseBannerService.deleteBanner(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner deleted successfully'),
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
                'Promotional Banners',
                style: TextStyle(
                  fontSize: 20,
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
                      await context.push('/banners/add');
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Banner',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
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
          _buildBannersStream(),
        ],
      ),
    );
  }

  Widget _buildBannersStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseBannerService.getBanners(),
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

        final banners = snapshot.data ?? [];

        if (banners.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.view_carousel_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No banners found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return _buildBannersGrid(context, banners);
      },
    );
  }

  Widget _buildBannersGrid(
      BuildContext context, List<Map<String, dynamic>> banners) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 1.6;

        if (width < 800) {
          crossAxisCount = 1;
          childAspectRatio = 1.5;
        } else if (width >= 1200) {
          childAspectRatio = 2.0;
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
          itemCount: banners.length,
          itemBuilder: (context, index) {
            final banner = banners[index];
            return BannerCard(
              title: banner['title'] ?? 'No Title',
              description: banner['description'] ?? '',
              position: 'Order: ${banner['order'] ?? 0}',
              status:
                  (banner['isActive'] == true) ? 'Published' : 'Unpublished',
              imageUrl: banner['imageUrl'],
              placeholderColor: Colors.purple.shade200,
              onEdit: () async {
                final editData = {
                  ...banner,
                  'firebaseId': banner['id'],
                };
                await context.push('/banners/add', extra: editData);
              },
              onDelete: () => _deleteBanner(banner['id'], banner['mongoId']),
            );
          },
        );
      },
    );
  }
}

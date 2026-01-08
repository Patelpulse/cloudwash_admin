import 'dart:convert';

import 'package:cloud_admin/features/banners/widgets/banner_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<dynamic> _banners = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    try {
      final baseUrl = AppConfig.apiUrl;
      final response = await http.get(Uri.parse('$baseUrl/banners'));

      if (response.statusCode == 200) {
        setState(() {
          _banners = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load banners';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBanner(String id) async {
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
        final baseUrl = AppConfig.apiUrl;
        final response = await http.delete(Uri.parse('$baseUrl/banners/$id'));

        if (response.statusCode == 200) {
          _fetchBanners(); // Refresh list
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Banner deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete banner')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(child: Text(_errorMessage));
    }

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
              ElevatedButton.icon(
                onPressed: () async {
                  await context.push('/banners/add');
                  _fetchBanners();
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Banner',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _banners.isEmpty
              ? const Center(child: Text('No banners found.'))
              : _buildBannersGrid(context),
        ],
      ),
    );
  }

  Widget _buildBannersGrid(BuildContext context) {
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
          itemCount: _banners.length,
          itemBuilder: (context, index) {
            final banner = _banners[index];
            return BannerCard(
              title: banner['title'] ?? 'No Title',
              description: banner['description'] ?? '',
              position: banner['position'] ?? 'Home Top Slider',
              status:
                  (banner['isActive'] == true) ? 'Published' : 'Unpublished',
              imageUrl: banner['imageUrl'],
              placeholderColor: Colors.purple.shade200,
              onEdit: () async {
                await context.push('/banners/add', extra: banner);
                _fetchBanners();
              },
              onDelete: () => _deleteBanner(banner['_id']),
            );
          },
        );
      },
    );
  }
}

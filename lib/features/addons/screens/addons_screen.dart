import 'dart:convert';

import 'package:cloud_admin/features/addons/widgets/addon_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

class AddonsScreen extends StatefulWidget {
  const AddonsScreen({super.key});

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen> {
  List<dynamic> _addons = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchAddons();
  }

  Future<void> _fetchAddons() async {
    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
      final response = await http.get(Uri.parse('$baseUrl/addons'));

      if (response.statusCode == 200) {
        setState(() {
          _addons = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load addons';
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

  Future<void> _deleteAddon(String id) async {
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
        final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
        final response = await http.delete(Uri.parse('$baseUrl/addons/$id'));

        if (response.statusCode == 200) {
          _fetchAddons(); // Refresh list
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add-on deleted successfully')),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to delete add-on')),
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
          const Text(
            'Service Add-ons',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Orange Header/Button Bar
          InkWell(
            onTap: () async {
              await context.push('/addons/add');
              _fetchAddons();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEA8C00), // Orange color
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: const [
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
          const SizedBox(height: 16),
          // Filter Section
          const Text(
            'Filter by Category:',
            style: TextStyle(
                color: Colors.blueGrey,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('All Categories',
                    style: TextStyle(fontWeight: FontWeight.w500)),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
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
          _buildGrid(context),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    if (_addons.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text('No add-ons found. Click "New Add-on" to create one.'),
        ),
      );
    }

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
          itemCount: _addons.length,
          itemBuilder: (context, index) {
            final addon = _addons[index];
            return AddonCard(
              title: addon['name'] ?? 'No Name',
              description: addon['description'] ?? '',
              price: '₹${addon['price']}',
              duration: addon['duration'] ?? '',
              imageUrl: addon['imageUrl'],
              placeholderColor: Colors.grey.shade800,
              onEdit: () async {
                await context.push('/addons/add', extra: addon);
                _fetchAddons();
              },
              onDelete: () => _deleteAddon(addon['_id']),
            );
          },
        );
      },
    );
  }
}

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class WebHomePageScreen extends StatelessWidget {
  const WebHomePageScreen({super.key});

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
                'Web Home Page Content',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.save, size: 18, color: Colors.white),
                label: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildHeroSection(),
          const SizedBox(height: 24),
          _buildAboutSection(),
          const SizedBox(height: 24),
          _buildContactSection(),
        ],
      ),
    );
  }

  Widget _buildSectionContainer(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return _buildSectionContainer(
      title: 'Hero Section (Top Banner)',
      children: const [
        TextField(
          decoration: InputDecoration(
            labelText: 'Main Headline',
            hintText: 'e.g. Premium Laundry Services at Your Doorstep',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Sub Headline',
            hintText: 'e.g. Schedule a pickup in seconds',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Hero Button Text',
            hintText: 'e.g. Book Now',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _buildSectionContainer(
      title: 'About Section',
      children: const [
        TextField(
          decoration: InputDecoration(
            labelText: 'About Title',
            border: OutlineInputBorder(),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSectionContainer(
      title: 'Footer Contact Info',
      children: const [
        TextField(
          decoration: InputDecoration(
            labelText: 'Support Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Support Phone',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.phone),
          ),
        ),
        SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: 'Office Address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WebLandingScreen extends ConsumerWidget {
  const WebLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Web Landing Page Content',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Manage the content of your public landing page',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),

            // Grid of Editable Sections
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                childAspectRatio: 1.5,
                children: [
                  _SectionCard(
                    title: 'Hero Section',
                    description: 'Edit main title, tagline, and hero image',
                    icon: Icons.view_carousel,
                    color: Colors.blue.shade100,
                    onTap: () => context.go('/web-landing/hero'),
                  ),
                  _SectionCard(
                    title: 'About Us',
                    description: 'Update company story and experience',
                    icon: Icons.info_outline,
                    color: Colors.green.shade100,
                    onTap: () => context.go('/web-landing/about'),
                  ),
                  _SectionCard(
                    title: 'Why Choose Us',
                    description: 'Manage features and benefits cards',
                    icon: Icons.check_circle_outline,
                    color: Colors.orange.shade100,
                    onTap: () => context.go('/web-landing/why-choose-us'),
                  ),
                  _SectionCard(
                    title: 'Stats',
                    description: 'Update counters (Clients, Branches, etc.)',
                    icon: Icons.analytics_outlined,
                    color: Colors.purple.shade100,
                    onTap: () => context.go('/web-landing/stats'),
                  ),
                  _SectionCard(
                    title: 'Testimonials',
                    description: 'Manage customer reviews and ratings',
                    icon: Icons.rate_review_outlined,
                    color: Colors.pink.shade100,
                    onTap: () => context.go('/web-landing/testimonials'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _SectionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: Colors.black87),
              ),
              const Spacer(),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

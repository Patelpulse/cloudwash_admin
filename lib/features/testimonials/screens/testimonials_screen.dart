import 'package:cloud_admin/features/testimonials/widgets/testimonial_card.dart';
import 'package:flutter/material.dart';

class TestimonialsScreen extends StatelessWidget {
  const TestimonialsScreen({super.key});

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
                'Customer Testimonials',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: const Text('Add Testimonial',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEC4899), // Pink color from screenshot
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildGrid(context),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    // Mock Data
    final testimonials = [
      _TestimonialData(
        'Rishav Sengar',
        'Customer',
        5,
        'Best services ',
        'R',
        Colors.pinkAccent,
      ),
      _TestimonialData(
        'Rohit Sengar',
        'Customer',
        5,
        'All services are best . Best prices and Best Quality offered ',
        'R',
        Colors.pinkAccent,
      ),
      _TestimonialData(
        'Yogesh Thakur',
        'Customer',
        5,
        'Urbanprox  provides Quality services ',
        'Y',
        Colors.pinkAccent,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        double childAspectRatio = 1.3;

        if (width < 1100) {
          crossAxisCount = 2;
          childAspectRatio = 1.3;
        }
        if (width < 700) {
          crossAxisCount = 1;
          childAspectRatio = 1.6;
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
          itemCount: testimonials.length,
          itemBuilder: (context, index) {
            final item = testimonials[index];
            return TestimonialCard(
              name: item.name,
              role: item.role,
              rating: item.rating,
              review: item.review,
              avatarLetter: item.avatarLetter,
              avatarColor: item.color,
              onEdit: () {},
              onDelete: () {},
            );
          },
        );
      },
    );
  }
}

class _TestimonialData {
  final String name;
  final String role;
  final double rating;
  final String review;
  final String avatarLetter;
  final Color color;

  _TestimonialData(this.name, this.role, this.rating, this.review,
      this.avatarLetter, this.color);
}

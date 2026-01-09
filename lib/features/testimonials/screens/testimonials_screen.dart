import 'package:cloud_admin/core/services/firebase_testimonial_service.dart';
import 'package:cloud_admin/features/testimonials/widgets/testimonial_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TestimonialsScreen extends StatefulWidget {
  const TestimonialsScreen({super.key});

  @override
  State<TestimonialsScreen> createState() => _TestimonialsScreenState();
}

class _TestimonialsScreenState extends State<TestimonialsScreen> {
  final _firebaseTestimonialService = FirebaseTestimonialService();

  Future<void> _deleteTestimonial(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content:
            const Text('Are you sure you want to delete this testimonial?'),
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
        await _firebaseTestimonialService.deleteTestimonial(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Testimonial deleted successfully'),
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
                'Customer Testimonials',
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
                      await context.push('/testimonials/add');
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Testimonial',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEC4899),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTestimonialsStream(),
        ],
      ),
    );
  }

  Widget _buildTestimonialsStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseTestimonialService.getTestimonials(),
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

        final testimonials = snapshot.data ?? [];

        if (testimonials.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Icon(Icons.reviews_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No testimonials found',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first customer testimonial',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return _buildGrid(context, testimonials);
      },
    );
  }

  Widget _buildGrid(
      BuildContext context, List<Map<String, dynamic>> testimonials) {
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
            final testimonial = testimonials[index];
            final name = testimonial['name'] ?? 'Anonymous';
            final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : 'A';

            return TestimonialCard(
              name: name,
              role: testimonial['designation'] ?? 'Customer',
              rating: (testimonial['rating'] ?? 5.0).toDouble(),
              review: testimonial['message'] ?? '',
              avatarLetter: avatarLetter,
              avatarColor: Colors.pinkAccent,
              onEdit: () async {
                final editData = {
                  ...testimonial,
                  'firebaseId': testimonial['id'],
                };
                await context.push('/testimonials/add', extra: editData);
              },
              onDelete: () =>
                  _deleteTestimonial(testimonial['id'], testimonial['mongoId']),
            );
          },
        );
      },
    );
  }
}

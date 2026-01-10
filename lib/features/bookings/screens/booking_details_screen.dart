import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/bookings/data/bookings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class BookingDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailsScreen({super.key, required this.booking});

  @override
  ConsumerState<BookingDetailsScreen> createState() =>
      _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends ConsumerState<BookingDetailsScreen> {
  bool _isLoading = false;

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      final dbId = widget.booking['_id'];
      final userId = widget.booking['userId'];

      await ref
          .read(bookingsRepositoryProvider)
          .updateBookingStatus(dbId, newStatus, userId: userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status updated to $newStatus')));
        context.pop(); // Go back to list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final status = booking['status'] as String? ?? 'pending';
    final services = (booking['services'] as List?) ?? [];
    final address = booking['address'] ?? {};
    final user = booking['user'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text('Booking #${booking['orderNumber']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(status),
                            color: _getStatusColor(status)),
                        const SizedBox(width: 12),
                        Text(
                          'Current Status: ${status.toUpperCase()}',
                          style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Layout (Responsive)
                  LayoutBuilder(builder: (context, constraints) {
                    return constraints.maxWidth > 800
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 2,
                                  child: _buildMainContent(
                                      booking, services, address)),
                              const SizedBox(width: 24),
                              Expanded(
                                  flex: 1, child: _buildSidebar(booking, user)),
                            ],
                          )
                        : Column(
                            children: [
                              _buildMainContent(booking, services, address),
                              const SizedBox(height: 24),
                              _buildSidebar(booking, user),
                            ],
                          );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildMainContent(Map booking, List services, Map address) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Services', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ...services.map((s) => ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.cleaning_services,
                            color: Colors.blue),
                      ),
                      title: Text(s['name']),
                      subtitle: Text('Qty: ${s['quantity']}'),
                      trailing: Text('₹${(s['total'] as num).toInt()}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    )),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(
                        '₹${(booking['priceSummary']?['total'] as num? ?? 0).toInt()}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                  ],
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${address['houseNumber'] ?? ''} ${address['street'] ?? 'No Street'}, ${address['city'] ?? ''}, ${address['pincode'] ?? ''}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (address['phone'] != null)
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined, color: Colors.grey),
                      const SizedBox(width: 12),
                      Text(address['phone'],
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar(Map booking, Map user) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text(user['name']?[0] ?? 'U')),
                  title: Text(user['name'] ?? 'Unknown'),
                  subtitle: Text(user['email'] ?? ''),
                ),
                if (user['phone'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(user['phone'],
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actions', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _actionButton('Mark as Confirmed', 'confirmed', Colors.blue),
                const SizedBox(height: 12),
                _actionButton('Mark In Progress', 'in-progress', Colors.orange),
                const SizedBox(height: 12),
                _actionButton('Mark Completed', 'completed', Colors.green),
                const SizedBox(height: 12),
                _actionButton('Cancel Order', 'cancelled', Colors.red),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(String label, String status, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () => _updateStatus(status),
        child: Text(label),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.thumb_up;
      case 'in-progress':
        return Icons.work;
      default:
        return Icons.help;
    }
  }
}

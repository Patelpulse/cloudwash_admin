import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/bookings/screens/booking_details_screen.dart';
import 'package:cloud_admin/features/bookings/widgets/booking_list_item.dart';
import 'package:cloud_admin/features/users/widgets/user_stats_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final bookingsStreamProvider =
    StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  return FirebaseFirestore.instance
      .collection('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((event) => event.docs);
});

class BookingsScreen extends ConsumerWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: bookingsAsync.when(
        data: (docs) {
          final total = docs.length;
          final completed = docs
              .where((doc) => (doc.data() as Map)['status'] == 'completed')
              .length;
          final pending = docs
              .where((doc) => (doc.data() as Map)['status'] == 'pending')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(context, total, completed, pending),
                const SizedBox(height: 32),
                _buildFilters(context),
                const SizedBox(height: 32),
                Text(
                  'All Bookings ($total)',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                if (docs.isEmpty)
                  const Center(child: Text("No bookings found"))
                else
                  ...docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Extract first service name or default
                    final services = data['services'] as List?;
                    final title = (services != null && services.isNotEmpty)
                        ? services[0]['name']
                        : 'Service Booking';

                    return BookingListItem(
                      title: title,
                      id: '#${data['orderNumber'] ?? doc.id.substring(0, 6)}',
                      status: data['status'] ?? 'pending',
                      customer: data['user']?['name'] ?? 'Unknown',
                      date: data['createdAt'] != null
                          ? DateFormat('MMM dd, yyyy \u2022 h:mm a')
                              .format(DateTime.parse(data['createdAt']))
                          : 'N/A',
                      amount: '₹${data['priceSummary']?['total'] ?? 0}',
                      onTap: () {
                        // Ensure ID is passed for updates
                        final bookingData = Map<String, dynamic>.from(data);
                        bookingData['_id'] = doc
                            .id; // Firestore doc ID usually matches functionality needed
                        // Note: If backend expects MongoDB _id, it should be in data['_id'] if synced correctly.
                        // If not, we might need to rely on what's available.

                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => BookingDetailsScreen(
                                    booking: bookingData)));
                      },
                    );
                  }),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, int total, int completed, int pending) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 800) crossAxisCount = 1;

        if (crossAxisCount == 1) {
          return Column(
            children: [
              UserStatsCard(
                  label: 'Total Bookings',
                  value: total.toString(),
                  icon: Icons.calendar_today,
                  color: Colors.blue),
              const SizedBox(height: 16),
              UserStatsCard(
                  label: 'Completed',
                  value: completed.toString(),
                  icon: Icons.check_circle,
                  color: AppTheme.successGreen),
              const SizedBox(height: 16),
              UserStatsCard(
                  label: 'Pending',
                  value: pending.toString(),
                  icon: Icons.access_time_filled,
                  color: Colors.orange),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
                child: UserStatsCard(
                    label: 'Total Bookings',
                    value: total.toString(),
                    icon: Icons.calendar_today,
                    color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(
                child: UserStatsCard(
                    label: 'Completed',
                    value: completed.toString(),
                    icon: Icons.check_circle,
                    color: AppTheme.successGreen)),
            const SizedBox(width: 16),
            Expanded(
                child: UserStatsCard(
                    label: 'Pending',
                    value: pending.toString(),
                    icon: Icons.access_time_filled,
                    color: Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final isMobile = width < 600;

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search bookings...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (val) {
                // Implement search logic later or use local filtering
              },
            ),
          ),
          const SizedBox(height: 16),
          // Keeping date filter only, removing vendor filter as per sentiment
          SizedBox(
            width: double.infinity,
            child: _buildDropdown(Icons.calendar_month, 'All Dates'),
          ),
        ],
      );
    });
  }

  Widget _buildDropdown(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }
}

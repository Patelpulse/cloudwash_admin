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
  // Query all orders from all users using collection group
  // This gets orders from: users/{userId}/orders/{orderId}
  return FirebaseFirestore.instance
      .collectionGroup('orders') // ✅ Gets orders from ALL users
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((event) => event.docs);
});

class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    // Initialize seen orders on first load
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isFirstLoad = false);
      }
    });
  }

  void _showNewBookingPopup(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications_active,
                  color: Colors.green.shade700, size: 28),
            ),
            const SizedBox(width: 12),
            const Text('🔔 New Booking!', style: TextStyle(fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order #${data['orderNumber'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Customer: ${data['user']?['name'] ?? 'Unknown'}'),
            Text('Phone: ${data['user']?['phone'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text(
              'Amount: ₹${data['priceSummary']?['total'] ?? 0}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Auto-scroll or focus on the new booking
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5)),
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  void _playNotificationSound() {
    // Play browser notification sound
    // For web, we can use the Web Audio API through JS interop
    // For now, we'll use the HTML5 audio element via the browser
    try {
      // This will attempt to play the default notification sound
      // You can add a custom sound file to your assets and play it
      print('🔊 Playing notification sound...');
      // TODO: Add audio player package and custom sound
    } catch (e) {
      print('Could not play sound: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);

    // Listen for new bookings (runs outside build phase)
    ref.listen<AsyncValue<List<QueryDocumentSnapshot>>>(
      bookingsStreamProvider,
      (previous, next) {
        if (next is AsyncData && previous is AsyncData) {
          final newDocs = (next as AsyncData).value ?? [];
          final oldDocs = (previous as AsyncData).value ?? [];

          // Check if there's a new booking at the top
          if (newDocs.isNotEmpty && oldDocs.isNotEmpty && !_isFirstLoad) {
            if (newDocs.first.id != oldDocs.first.id) {
              // New booking detected!
              final data = newDocs.first.data() as Map<String, dynamic>;
              Future.microtask(() {
                if (mounted) {
                  _showNewBookingPopup(data);
                  _playNotificationSound();
                }
              });
            }
          }
        }

        // Mark first load complete after data arrives
        if (_isFirstLoad && next is AsyncData) {
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) setState(() => _isFirstLoad = false);
          });
        }
      },
    );

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
                          ? _formatDate(data['createdAt'])
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

  String _formatDate(dynamic value) {
    DateTime? dateTime;
    if (value is Timestamp) {
      dateTime = value.toDate();
    } else if (value is String) {
      dateTime = DateTime.tryParse(value);
    } else if (value is Map && value.containsKey('_seconds')) {
      final seconds = value['_seconds'] as int;
      final nanoseconds = value['_nanoseconds'] as int? ?? 0;
      dateTime = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000 + (nanoseconds / 1000000).floor(),
      );
    }
    return dateTime != null
        ? DateFormat('MMM dd, yyyy • h:mm a').format(dateTime)
        : 'N/A';
  }
}

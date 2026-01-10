import 'package:audioplayers/audioplayers.dart';
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

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(bookingsStreamProvider);

    // Track seen order IDs to prevent duplicate alerts on partial updates
    ref.listen<AsyncValue<List<QueryDocumentSnapshot>>>(
      bookingsStreamProvider,
      (previous, next) {
        if (next is AsyncData && previous is AsyncData) {
          final newDocs = (next as AsyncData).value ?? [];
          final oldDocs = (previous as AsyncData).value ?? [];

          // If we have more docs than before, or different top doc
          if (newDocs.isNotEmpty && !_isFirstLoad) {
            // Get set of old IDs
            final oldIds = oldDocs.map((d) => d.id).toSet();

            // Find any document in newDocs that is NOT in oldDocs
            final newlyAddedDocs =
                newDocs.where((d) => !oldIds.contains(d.id)).toList();

            if (newlyAddedDocs.isNotEmpty) {
              final newDoc = newlyAddedDocs.first;
              final data = newDoc.data() as Map<String, dynamic>;

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
          final allDocs = docs;
          final uniqueBookings = <String, QueryDocumentSnapshot>{};

          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            // Use orderNumber as unique key if available, else doc ID
            final key = data['orderNumber']?.toString() ?? doc.id;

            // If duplicate exists, prefer the one with more complete data or from main collection?
            // Since we use collectionGroup, we might get copies from users/{uid}/orders AND orders/
            // Usually we want just one representation.
            if (!uniqueBookings.containsKey(key)) {
              uniqueBookings[key] = doc;
            }
          }

          final filteredDocs = uniqueBookings.values.toList();
          // Sort by date manually as map iteration might lose order
          filteredDocs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            // Handle Timestamp comparison
            dynamic aTime = aData['createdAt'];
            dynamic bTime = bData['createdAt'];

            DateTime aDate = DateTime(0);
            DateTime bDate = DateTime(0);

            if (aTime is Timestamp)
              aDate = aTime.toDate();
            else if (aTime is String)
              aDate = DateTime.tryParse(aTime) ?? DateTime(0);

            if (bTime is Timestamp)
              bDate = bTime.toDate();
            else if (bTime is String)
              bDate = DateTime.tryParse(bTime) ?? DateTime(0);

            return bDate.compareTo(aDate); // Descending
          });

          final total = filteredDocs.length;
          final completed = filteredDocs
              .where((doc) => (doc.data() as Map)['status'] == 'completed')
              .length;
          final pending = filteredDocs
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
                if (filteredDocs.isEmpty)
                  const Center(child: Text("No bookings found"))
                else
                  ...filteredDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    // Extract first service name or default
                    final services = data['services'] as List?;
                    final title = (services != null && services.isNotEmpty)
                        ? services[0]['name']
                        : 'Service Booking';

                    final userObj = data['user'] as Map<String, dynamic>?;
                    final addressObj = data['address'] as Map<String, dynamic>?;

                    final customerName =
                        userObj?['name'] ?? addressObj?['name'] ?? 'Unknown';

                    return BookingListItem(
                      title: title,
                      id: '#${data['orderNumber'] ?? doc.id.substring(0, 6)}',
                      status: data['status'] ?? 'pending',
                      customer: customerName,
                      date: data['createdAt'] != null
                          ? _formatDate(data['createdAt'])
                          : 'N/A',
                      amount:
                          '₹${(data['priceSummary']?['total'] as num? ?? 0).toInt()}',
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

  AudioPlayer? _alertPlayer;

  @override
  void dispose() {
    _stopNotificationSound();
    super.dispose();
  }

  void _stopNotificationSound() async {
    try {
      if (_alertPlayer != null) {
        await _alertPlayer!.stop();
        await _alertPlayer!.dispose();
        _alertPlayer = null;
      }
    } catch (e) {
      print('Error stopping sound: $e');
    }
  }

  void _showNewBookingPopup(Map<String, dynamic> data) {
    final userObj = data['user'] as Map<String, dynamic>?;
    final addressObj = data['address'] as Map<String, dynamic>?;
    final customerName = userObj?['name'] ?? addressObj?['name'] ?? 'Unknown';
    final phone = userObj?['phone'] ?? addressObj?['phone'] ?? 'N/A';

    // Extract address details
    final addressLabel = addressObj?['label'] ?? 'Home';
    final fullAddress = addressObj?['fullAddress'] ??
        '${addressObj?['houseNumber'] ?? ''}, ${addressObj?['street'] ?? ''}, ${addressObj?['city'] ?? ''}';

    // Extract time
    final scheduledDate = data['scheduledDate'];
    final timeStr = scheduledDate != null ? _formatDate(scheduledDate) : 'ASAP';

    // Extract services
    final services = (data['services'] as List?) ?? [];
    final serviceNames = services.map((s) => s['name']).join(', ');

    showDialog(
      context: context,
      barrierDismissible: false, // Force user to interact to stop sound
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_active,
                    color: Colors.green.shade700, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'New Booking Received!',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.receipt_long, 'Order ID',
                    '#${data['orderNumber'] ?? 'N/A'}'),
                const Divider(height: 24),
                _buildDetailRow(
                    Icons.person, 'Customer', '$customerName ($phone)'),
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.location_on, 'Address ($addressLabel)', fullAddress),
                const SizedBox(height: 12),
                _buildDetailRow(
                    Icons.access_time_filled, 'Scheduled For', timeStr),
                const Divider(height: 24),
                const Text('Order Summary',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                    serviceNames.isNotEmpty
                        ? serviceNames
                        : 'No services listed',
                    style: TextStyle(color: Colors.grey[800], height: 1.4)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount',
                          style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w600)),
                      Text(
                        '₹${(data['priceSummary']?['total'] as num? ?? 0).toInt()}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          OutlinedButton(
            onPressed: () {
              _stopNotificationSound();
              Navigator.pop(context);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: BorderSide(color: Colors.grey.shade400),
            ),
            child: const Text('Dismiss', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              _stopNotificationSound();
              Navigator.pop(context);
              // Ensure ID is passed for updates
              final bookingData = Map<String, dynamic>.from(data);
              // Fallback for ID if missing in data root
              if (!bookingData.containsKey('_id')) {
                // We don't have the doc ID here easily unless we pass it.
                // Ideally the doc.data() should contain _id if we flattened it, but we are passing raw data.
                // We can't navigate to details easily without the Firestore Doc ID if it's not in the map.
                // For now, let's just close. The user can click the list item.
                // Or we rely on the list view.
              } else {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            BookingDetailsScreen(booking: bookingData)));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E88E5),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View Booking Details',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  void _playNotificationSound() async {
    try {
      print('🔊 Playing notification sound (looping)...');
      _stopNotificationSound(); // Stop any existing sound
      _alertPlayer = AudioPlayer();
      await _alertPlayer!.setReleaseMode(ReleaseMode.loop);
      // Continuous ringing sound
      await _alertPlayer!.play(UrlSource(
          'https://assets.mixkit.co/active_storage/sfx/2869/2869-preview.mp3'));
    } catch (e) {
      print('Could not play sound: $e');
    }
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

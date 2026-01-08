import 'package:cloud_admin/core/services/socket_service.dart';
import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:audioplayers/audioplayers.dart';

class SocketListenerWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const SocketListenerWrapper({super.key, required this.child});

  @override
  ConsumerState<SocketListenerWrapper> createState() =>
      _SocketListenerWrapperState();
}

class _SocketListenerWrapperState extends ConsumerState<SocketListenerWrapper> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.init();

      socketService.onNewOrder((data) {
        if (mounted) {
          // Sanitize data to avoid basic JS object issues on Web
          final safeData = data is Map
              ? Map<String, dynamic>.from(data)
              : <String, dynamic>{};

          Future.delayed(Duration.zero, () {
            if (mounted) _showNewOrderDialog(safeData);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // On Web, this might require prior user interaction.
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (e) {
      print("Error playing sound (Autoplay might be blocked): $e");
    }
  }

  Future<void> _stopSound() async {
    try {
      await _audioPlayer.stop();
    } catch (e) {
      print("Error stopping sound: $e");
    }
  }

  void _showNewOrderDialog(Map<String, dynamic> data) async {
    // Start sound immediately
    _playSound();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => NewBookingDialog(data: data),
    );

    // Stop sound when closed
    _stopSound();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class NewBookingDialog extends StatelessWidget {
  final dynamic data;
  const NewBookingDialog({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final order = data['order'] ?? {};
    final services = (data['services'] as List?) ?? [];
    final address = data['address'] ?? {};
    final orderNumber = data['orderNumber']?.toString() ?? '---';
    final amount = data['amount']?.toString() ?? '0';
    final customerName = data['customerName']?.toString() ?? 'Unknown';
    final createdAt = data['createdAt'] != null
        ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
        : DateTime.now();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      shadowColor: Colors.black26,
      elevation: 20,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(orderNumber, createdAt),
                const SizedBox(height: 32),
                _buildStatisticsSection(amount, services.length),
                const SizedBox(height: 32),
                _buildSectionTitle('Customer Details'),
                const SizedBox(height: 16),
                _buildCustomerInfo(customerName, address),
                const SizedBox(height: 24),
                _buildSectionTitle('Services Requested'),
                const SizedBox(height: 16),
                _buildServicesList(services),
                const SizedBox(height: 40),
                _buildFooterActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String orderNumber, DateTime createdAt) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long,
                      color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'New Booking #$orderNumber',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Received on',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy, h:mm a').format(createdAt),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatisticsSection(String amount, int itemsCount) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'Total Amount',
            value: '₹$amount',
            icon: Icons.payments,
            color: Colors.green,
            progress: 1.0,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            label: 'Services Count',
            value: '$itemsCount Items',
            icon: Icons.list_alt,
            color: Colors.purple,
            progress: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 14, color: Colors.grey)),
            Icon(icon, color: color, size: 18),
          ],
        ),
        const SizedBox(height: 8),
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        )
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildCustomerInfo(String name, Map address) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade200,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                if (address.isNotEmpty)
                  Text(
                    '${address['houseNumber'] ?? ''} ${address['street'] ?? ''}, \n${address['city'] ?? ''}, ${address['pincode'] ?? ''}',
                    style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                  )
                else
                  const Text('No address provided',
                      style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                if (address['phone'] != null)
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(address['phone'],
                          style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildServicesList(List services) {
    if (services.isEmpty) return const Text('No services listed.');

    return Column(
      children: services.map<Widget>((service) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.cleaning_services,
                    size: 20, color: Colors.blueGrey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service['name'] ?? 'Service',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    Row(
                      children: [
                        Text('Qty: ${service['quantity'] ?? 1}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                        const SizedBox(width: 8),
                        Text('₹${service['total'] ?? 0}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Close',
                style: TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.go('/bookings'); // Navigate to details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5), // Indigo
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
            ),
            child: const Text('View Full Details',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

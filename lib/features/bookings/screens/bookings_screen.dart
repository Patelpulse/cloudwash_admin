import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/bookings/widgets/booking_list_item.dart';
import 'package:cloud_admin/features/users/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';

class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(context),
          const SizedBox(height: 32),
          _buildFilters(context),
          const SizedBox(height: 32),
          const Text(
            'All Bookings (127)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const BookingListItem(
            title: 'Bus Disinfection',
            id: '#c01084',
            status: 'Waiting_vendor_response',
            customer: 'New User',
            vendor: 'Yogesh Thakur',
            date: '1/2/2026',
            amount: '₹1499',
          ),
          const BookingListItem(
            title: 'LAN Cabling',
            id: '#bff604',
            status: 'Work_completed',
            customer: 'New User',
            vendor: 'Yogesh Sengar',
            date: '1/2/2026',
            amount: '₹3750', // Example amount
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Adapt layout
        if (width < 800) {
          return Column(
            children: const [
              UserStatsCard(
                  label: 'Total Bookings',
                  value: '127',
                  icon: Icons.calendar_today,
                  color: Colors.blue),
              SizedBox(height: 16),
              UserStatsCard(
                  label: 'Completed',
                  value: '19',
                  icon: Icons.check_circle,
                  color: AppTheme.successGreen),
              SizedBox(height: 16),
              UserStatsCard(
                  label: 'Pending',
                  value: '25',
                  icon: Icons.access_time_filled,
                  color: Colors.orange),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
                child: const UserStatsCard(
                    label: 'Total Bookings',
                    value: '127',
                    icon: Icons.calendar_today,
                    color: Colors.blue)),
            const SizedBox(width: 16),
            Expanded(
                child: const UserStatsCard(
                    label: 'Completed',
                    value: '19',
                    icon: Icons.check_circle,
                    color: AppTheme.successGreen)),
            const SizedBox(width: 16),
            Expanded(
                child: const UserStatsCard(
                    label: 'Pending',
                    value: '25',
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
            ),
          ),
          const SizedBox(height: 16),
          Flex(
            direction: isMobile ? Axis.vertical : Axis.horizontal,
            children: [
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _buildDropdown(Icons.store, 'All Vendors'),
              ),
              SizedBox(width: 16, height: isMobile ? 16 : 0),
              Expanded(
                flex: isMobile ? 0 : 1,
                child: _buildDropdown(Icons.calendar_month, 'All Dates'),
              ),
            ],
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

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/dashboard/widgets/dashboard_stats_card.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back,',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const Text(
            'Master Admin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 4;
              if (width < 600) {
                crossAxisCount = 1;
              } else if (width < 1100) {
                crossAxisCount = 2;
              }

              // Calculate aspect ratio based on width to keep cards looking good
              double aspectRatio = width < 600 ? 1.8 : 1.4;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: aspectRatio,
                children: const [
                  DashboardStatsCard(
                    title: 'Total Revenue',
                    value: '₹4,816.2',
                    icon: Icons.currency_rupee, // Or Icons.trending_up
                    color: AppTheme.successGreen,
                    growth: '+12.5%',
                  ),
                  DashboardStatsCard(
                    title: 'Total Bookings',
                    value: '127',
                    icon: Icons.calendar_today,
                    color: AppTheme.primaryBlue,
                    growth: '+8.2%',
                  ),
                  DashboardStatsCard(
                    title: 'Active Vendors',
                    value: '4',
                    icon: Icons.store,
                    color: AppTheme.vendorsPurple,
                    growth: '+5.1%',
                  ),
                  DashboardStatsCard(
                    title: 'Total Users',
                    value: '4',
                    icon: Icons.person,
                    color: AppTheme.usersOrange,
                    growth: '+15.3%',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Booking Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 3;
              if (width < 800) crossAxisCount = 1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5,
                children: const [
                  _BookingOverviewCard(
                    label: 'Pending',
                    count: '25',
                    color: Colors.orange,
                    icon: Icons.access_time_filled,
                  ),
                  _BookingOverviewCard(
                    label: 'Completed',
                    count: '19',
                    color: Colors.green,
                    icon: Icons.check_circle,
                  ),
                  _BookingOverviewCard(
                    label: 'Cancelled',
                    count: '22',
                    color: Colors.red,
                    icon: Icons.cancel,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount = 4; // Design usually 4 cols.
              if (width < 600)
                crossAxisCount = 1;
              else if (width < 900)
                crossAxisCount = 2;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3.5, // Wide buttons
                children: const [
                  _QuickActionCard(
                    icon: Icons.category,
                    label: 'Categories',
                    color: Colors.blue,
                  ),
                  _QuickActionCard(
                    icon: Icons.image,
                    label: 'Banners',
                    color: Colors.purple,
                  ),
                  _QuickActionCard(
                    icon: Icons.location_on,
                    label: 'Cities',
                    color: Colors.green,
                  ),
                  _QuickActionCard(
                    icon: Icons.extension,
                    label: 'Add-ons',
                    color: Colors.orange,
                  ),

                  _QuickActionCard(
                    icon: Icons.format_quote,
                    label: 'Testimonials',
                    color: Colors.pink,
                  ),
                  _QuickActionCard(
                    icon: Icons.payment,
                    label: 'Payouts',
                    color: Colors.indigo,
                  ),
                  _QuickActionCard(
                    icon: Icons.notifications,
                    label: 'Notifications',
                    color: Colors.red,
                  ),
                  _QuickActionCard(
                    icon: Icons.build,
                    label: 'Services',
                    color: Colors.teal,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BookingOverviewCard extends StatelessWidget {
  final String label;
  final String count;
  final Color color;
  final IconData icon;

  const _BookingOverviewCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

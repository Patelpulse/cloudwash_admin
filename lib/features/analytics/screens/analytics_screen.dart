import 'package:cloud_admin/features/analytics/widgets/analytics_stat_card.dart';
import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            'Key metrics and growth indicators',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          _buildOverviewGrid(context),
          const SizedBox(height: 32),

          const Text(
            'Revenue Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildRevenueChartPlaceholder(),

          const SizedBox(height: 32),
          // Additional Sections Requested (5 more)
          _buildAdditionalSectionsGrid(context),
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(BuildContext context) {
    final List<Widget> cards = [
      const AnalyticsStatCard(
        label: 'Total Revenue',
        sublabel: 'Total earnings from all bookings',
        value: '₹0',
        icon: Icons.currency_rupee,
        growth: '+15%',
        gradientColors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ),
      const AnalyticsStatCard(
        label: 'User Growth',
        sublabel: 'New users registered this month',
        value: '0',
        icon: Icons.people,
        growth: '+12%',
        gradientColors: [Color(0xFFEC4899), Color(0xFFF472B6)],
      ),
      const AnalyticsStatCard(
        label: 'Booking Rate',
        sublabel: 'Total bookings processed',
        value: '0',
        icon: Icons.calendar_today,
        growth: '+8%',
        gradientColors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
      ),
      const AnalyticsStatCard(
        label: 'Active Vendors',
        sublabel: 'Vendors currently active',
        value: '0',
        icon: Icons.work,
        growth: '+5%',
        gradientColors: [Color(0xFF10B981), Color(0xFF34D399)],
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 4;
        double childAspectRatio = 0.8;

        if (width < 600) {
          crossAxisCount = 1;
          childAspectRatio = 1.5;
        } else if (width < 1100) {
          crossAxisCount = 2;
          childAspectRatio = 1.1;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: childAspectRatio,
          children: cards,
        );
      },
    );
  }

  Widget _buildRevenueChartPlaceholder() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Chart visualization coming soon',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalSectionsGrid(BuildContext context) {
    // 5 Additional Sections
    // 1. Top Performing Services
    // 2. Recent Payouts
    // 3. Customer Satisfaction
    // 4. Regional Distribution
    // 5. System Health

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 900;

        return Column(
          children: [
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _buildTopServicesCard()),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: _buildCustomerSatisfactionCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildTopServicesCard(),
                  const SizedBox(height: 24),
                  _buildCustomerSatisfactionCard(),
                ],
              ),
            const SizedBox(height: 24),
            _buildRecentPayoutsCard(),
            const SizedBox(height: 24),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildRegionDistributionCard()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSystemHealthCard()),
                ],
              )
            else
              Column(
                children: [
                  _buildRegionDistributionCard(),
                  const SizedBox(height: 24),
                  _buildSystemHealthCard(),
                ],
              ),
          ],
        );
      },
    );
  }

  // Section 1: Top Services
  Widget _buildTopServicesCard() {
    return _AnalyticsCardShell(
      title: 'Top Performing Services',
      child: Column(
        children: [
          _buildServiceRow('Deep Cleaning', 0.8, Colors.blue),
          const SizedBox(height: 16),
          _buildServiceRow('AC Repair', 0.65, Colors.orange),
          const SizedBox(height: 16),
          _buildServiceRow('Pest Control', 0.45, Colors.red),
          const SizedBox(height: 16),
          _buildServiceRow('Plumbing', 0.3, Colors.teal),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String name, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('${(percent * 100).toInt()}%',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percent,
          backgroundColor: color.withValues(alpha: 0.1),
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  // Section 2: Customer Satisfaction
  Widget _buildCustomerSatisfactionCard() {
    return _AnalyticsCardShell(
      title: 'Customer Satisfaction',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                '4.8',
                style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              Icon(Icons.star, size: 32, color: Colors.amber),
            ],
          ),
          const Text('Average Rating', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          _buildRatingRow(5, 120),
          _buildRatingRow(4, 45),
          _buildRatingRow(3, 12),
          _buildRatingRow(2, 4),
          _buildRatingRow(1, 2),
        ],
      ),
    );
  }

  Widget _buildRatingRow(int star, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$star',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: count / 150, // Mock total
              color: Colors.amber,
              backgroundColor: Colors.grey.shade100,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // Section 3: Recent Payouts
  Widget _buildRecentPayoutsCard() {
    return _AnalyticsCardShell(
      title: 'Recent Payouts',
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (_, index) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Colors.green.shade50,
              child: const Icon(Icons.attach_money, color: Colors.green),
            ),
            title: Text('Vendor #${1001 + index}'),
            subtitle: Text('Processed on Dec ${20 - index}, 2025'),
            trailing: Text(
              '₹${(index + 1) * 2500}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          );
        },
      ),
    );
  }

  // Section 4: Regional Distribution
  Widget _buildRegionDistributionCard() {
    return _AnalyticsCardShell(
      title: 'Top Cities',
      child: Column(
        children: [
          _buildCityStat('Mumbai', '45%'),
          const SizedBox(height: 12),
          _buildCityStat('Delhi', '30%'),
          const SizedBox(height: 12),
          _buildCityStat('Bangalore', '15%'),
          const SizedBox(height: 12),
          _buildCityStat('Other', '10%'),
        ],
      ),
    );
  }

  Widget _buildCityStat(String city, String percent) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: Colors.indigo),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(city)),
        Text(percent, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  // Section 5: System Health
  Widget _buildSystemHealthCard() {
    return _AnalyticsCardShell(
      title: 'System Health',
      child: Column(
        children: [
          _buildHealthIndicator('API Latency', '24ms', Colors.green),
          const SizedBox(height: 16),
          _buildHealthIndicator('Server Load', '42%', Colors.blue),
          const SizedBox(height: 16),
          _buildHealthIndicator('Error Rate', '0.01%', Colors.green),
          const SizedBox(height: 16),
          _buildHealthIndicator('Database', 'Healthy', Colors.green),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Text(
            value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsCardShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _AnalyticsCardShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

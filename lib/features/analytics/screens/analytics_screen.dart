import 'package:cloud_admin/features/dashboard/data/dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return statsAsync.when(
      data: (stats) => Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header & Page Controls
              _buildHeader(),
              const SizedBox(height: 32),

              // 2. Key Metric Row (4 Premium Cards)
              _buildQuickStats(stats),
              const SizedBox(height: 32),

              // Middle Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. Performance Overview (Large Bar Chart)
                  Expanded(flex: 3, child: _buildPerformanceChart(stats)),
                  const SizedBox(width: 24),
                  // Sidebar Analytics
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        // 4. Sales Analytics Gauge
                        _buildGrowthGauge(stats),
                        const SizedBox(height: 24),
                        // 5. Growth Benchmarks
                        _buildGrowthBenchmarks(stats),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 6. Top Services Distribution
                  Expanded(child: _buildServiceDistribution(stats)),
                  const SizedBox(width: 24),
                  // 7. Order Status Analytics
                  Expanded(child: _buildStatusDonut(stats)),
                  const SizedBox(width: 24),
                  // 8. Customer Activity
                  Expanded(child: _buildCustomerActivity(stats)),
                ],
              ),
              const SizedBox(height: 32),

              // 9. Recent Transactions Table
              _buildRecentOrdersTable(stats),

              const SizedBox(height: 32),
              // 10. Reporting Hub
              _buildReportingHub(),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales Overview',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B39)),
            ),
            Text(
              'Your current sales summary and activity',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Text(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          const SizedBox(width: 8),
          const Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label,
      {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF6C5DD3) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isPrimary ? Colors.transparent : Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 18, color: isPrimary ? Colors.white : Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isPrimary ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Total Sales',
            stats.totalOrders.toString(),
            '${stats.orderGrowth.toStringAsFixed(1)}%',
            'Last month: ${stats.lastMonthOrders}',
            const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            Icons.shopping_cart_outlined,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            'New Customer',
            stats.lastMonthUsers
                .toString(), // Mock showing current month's new users
            '${stats.userGrowth.toStringAsFixed(1)}%',
            'Last month: ${stats.lastMonthUsers}',
            null,
            Icons.group_outlined,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            'Cancelled Orders',
            stats.cancelledOrders.toString(),
            '${((stats.cancelledOrders - stats.lastMonthCancelled) / (stats.lastMonthCancelled + 1) * 100).toStringAsFixed(1)}%',
            'Last month: ${stats.lastMonthCancelled}',
            null,
            Icons.layers_outlined,
            isNegative: true,
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: _buildStatCard(
            'Total Revenue',
            '₹${stats.totalRevenue.toStringAsFixed(2)}',
            '${stats.revenueGrowth.toStringAsFixed(1)}%',
            'Last month: ₹${stats.lastMonthRevenue.toStringAsFixed(0)}',
            null,
            Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String growth,
      String comparison, List<Color>? gradient, IconData icon,
      {bool isNegative = false}) {
    final bool hasGradient = gradient != null;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hasGradient ? null : Colors.white,
        gradient: hasGradient
            ? LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)
            : null,
        borderRadius: BorderRadius.circular(24),
        boxShadow: hasGradient
            ? [
                BoxShadow(
                    color: gradient.first.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4))
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: hasGradient ? Colors.white70 : Colors.grey,
                      fontSize: 13)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : const Color(0xFFF3F3F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    color: hasGradient ? Colors.white : const Color(0xFF6C5DD3),
                    size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: hasGradient ? Colors.white : const Color(0xFF1E1B39),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: hasGradient
                      ? Colors.white.withValues(alpha: 0.2)
                      : (isNegative ? Colors.red[50] : Colors.green[50]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(isNegative ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 10,
                        color: hasGradient
                            ? Colors.white
                            : (isNegative ? Colors.red : Colors.green)),
                    Text(
                      growth,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasGradient
                            ? Colors.white
                            : (isNegative ? Colors.red : Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(comparison,
              style: TextStyle(
                  color: hasGradient ? Colors.white60 : Colors.grey[400],
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(DashboardStats stats) {
    return Container(
      height: 440,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Performance Overview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildActionDropdown('This Week'),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (stats.monthlyRevenue.values
                                .reduce((a, b) => a > b ? a : b) /
                            1000)
                        .ceilToDouble() +
                    5,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.white,
                    tooltipRoundedRadius: 12,
                    tooltipPadding: const EdgeInsets.all(16),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final monthKey =
                          stats.monthlyRevenue.keys.elementAt(groupIndex);
                      return BarTooltipItem(
                        '$monthKey 2026\n',
                        const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        children: [
                          TextSpan(
                            text:
                                'Total Sales: ${stats.monthlyOrders[monthKey]}\n',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                          TextSpan(
                            text:
                                'Total Revenue: ₹${(rod.toY * 1000).toStringAsFixed(0)}',
                            style: const TextStyle(
                                color: Color(0xFF6C5DD3),
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}k',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final keys = stats.monthlyRevenue.keys.toList();
                        if (value.toInt() >= 0 && value.toInt() < keys.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(keys[value.toInt()],
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 11)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (_) =>
                        FlLine(color: Colors.grey[50]!, strokeWidth: 1)),
                borderData: FlBorderData(show: false),
                barGroups: stats.monthlyRevenue.values
                    .toList()
                    .asMap()
                    .entries
                    .map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value / 1000,
                        width: 40,
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                            colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthGauge(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.grey[300]),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: 180,
                    sectionsSpace: 0,
                    centerSpaceRadius: 70,
                    sections: [
                      PieChartSectionData(
                          value: stats.revenueGrowth.clamp(0.0, 100.0),
                          color: const Color(0xFF3B82F6),
                          radius: 25,
                          showTitle: false),
                      PieChartSectionData(
                          value: 100 - stats.revenueGrowth.clamp(0.0, 100.0),
                          color: const Color(0xFFF3F3F9),
                          radius: 25,
                          showTitle: false),
                      PieChartSectionData(
                          value: 100,
                          color: Colors.transparent,
                          radius: 25,
                          showTitle: false), // Spacer for half-circle
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${stats.revenueGrowth.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1B39))),
                    const Text('Sales Growth',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthBenchmarks(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard('Number of Sales',
              stats.totalOrders.toString(), stats.orderGrowth >= 0),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSmallStatCard(
              'Total Revenue',
              '₹${(stats.totalRevenue / 1000).toStringAsFixed(1)}k',
              stats.revenueGrowth >= 0),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard(String label, String value, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.orange : Colors.red)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('+4.5%',
                    style: TextStyle(
                        fontSize: 10,
                        color: isPositive ? Colors.orange : Colors.red,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDistribution(DashboardStats stats) {
    return _SectionCard(
      title: 'Top Performing Services',
      child: Column(
        children: stats.servicePerformance
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500, fontSize: 13)),
                          Text('${(p['progress'] * 100).toInt()}%',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: p['progress'],
                        color: const Color(0xFF6C5DD3),
                        backgroundColor: const Color(0xFFF3F3F9),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildStatusDonut(DashboardStats stats) {
    return _SectionCard(
      title: 'Order Status Analytics',
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                      value: (stats.orderStatusCounts['paid'] ?? 0).toDouble(),
                      color: const Color(0xFF6C5DD3),
                      radius: 15,
                      showTitle: false),
                  PieChartSectionData(
                      value:
                          (stats.orderStatusCounts['pending'] ?? 0).toDouble(),
                      color: const Color(0xFF3B82F6),
                      radius: 15,
                      showTitle: false),
                  PieChartSectionData(
                      value:
                          (stats.orderStatusCounts['overdue'] ?? 0).toDouble(),
                      color: Colors.red[300],
                      radius: 15,
                      showTitle: false),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildLegendRow(
              'Completed',
              stats.orderStatusCounts['paid'].toString(),
              const Color(0xFF6C5DD3)),
          _buildLegendRow(
              'Pending',
              stats.orderStatusCounts['pending'].toString(),
              const Color(0xFF3B82F6)),
          _buildLegendRow('Cancelled',
              stats.orderStatusCounts['overdue'].toString(), Colors.red[300]!),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCustomerActivity(DashboardStats stats) {
    return _SectionCard(
      title: 'Recent Activity',
      child: Column(
        children: stats.recentUsers
            .map((u) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        u['image'] != null ? NetworkImage(u['image']) : null,
                    child: u['image'] == null
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  title: Text(u['name'],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('Registered as ${u['role']}',
                      style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right,
                      size: 16, color: Colors.grey),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildRecentOrdersTable(DashboardStats stats) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recent orders',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Container(
                      width: 250,
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: const Color(0xFFFBFBFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[100]!)),
                      child: Row(children: [
                        Icon(Icons.search, size: 16, color: Colors.grey[400]),
                        const SizedBox(width: 8),
                        const Text('Search products...',
                            style: TextStyle(color: Colors.grey, fontSize: 12))
                      ]),
                    ),
                    const SizedBox(width: 12),
                    _buildActionDropdown('Sort by'),
                  ],
                ),
              ],
            ),
          ),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(50),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1.5),
              4: FlexColumnWidth(1),
              5: FlexColumnWidth(1),
              6: FlexColumnWidth(1),
              7: FixedColumnWidth(100),
            },
            children: [
              TableRow(
                decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    border: Border.symmetric(
                        horizontal: BorderSide(color: Colors.grey[50]!))),
                children: [
                  '#',
                  'Order Id',
                  'Date',
                  'Customer',
                  'Category',
                  'Status',
                  'Items',
                  'Total'
                ]
                    .map((c) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(c,
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12))))
                    .toList(),
              ),
              ...stats.recentOrders.asMap().entries.map((e) => TableRow(
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.grey[50]!))),
                    children: [
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text((e.key + 1).toString(),
                              style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('#${e.value['id'].substring(0, 6)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(e.value['date'],
                              style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            CircleAvatar(
                                radius: 12,
                                backgroundImage:
                                    e.value['customerImage'] != null
                                        ? NetworkImage(e.value['customerImage'])
                                        : null),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(e.value['customerName'],
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis))
                          ])),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(e.value['category'],
                              style: const TextStyle(fontSize: 12))),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: _buildStatusBadge(e.value['status'])),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(e.value['items'],
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis)),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('₹${e.value['price'].toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold))),
                    ],
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.green;
    if (status == 'pending') color = Colors.orange;
    if (status == 'cancelled') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReportingHub() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF1E1B39), Color(0xFF2D2A4A)]),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 20,
                offset: const Offset(0, 8))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

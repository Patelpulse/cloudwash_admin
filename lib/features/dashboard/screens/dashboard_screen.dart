import 'package:cloud_admin/features/dashboard/data/dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1100;
    final isMobile = width < 700;

    return statsAsync.when(
      data: (stats) => Scaffold(
        backgroundColor: const Color(0xFFFBFBFB),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader(context),
              const SizedBox(height: 32),

              // Key Stats Section
              _buildStatsGrid(stats, isMobile, isDesktop),
              const SizedBox(height: 32),

              // Middle Section: Invoice Stats & Sales Analytics
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 1, child: _buildInvoiceStatistics(stats)),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildSalesAnalytics(stats)),
                  ],
                )
              else
                Column(
                  children: [
                    _buildInvoiceStatistics(stats),
                    const SizedBox(height: 24),
                    _buildSalesAnalytics(stats),
                  ],
                ),

              const SizedBox(height: 32),

              // Bottom Section: Recent Invoices
              _buildRecentInvoices(stats, isMobile),
            ],
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildModernHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back, Admin 👋',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1B39),
              ),
            ),
            Text(
              'Here is what\'s happening with your business today.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        if (MediaQuery.of(context).size.width > 800)
          Row(
            children: [
              Container(
                width: 300,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: Colors.grey[400]),
                    const SizedBox(width: 8),
                    Text('Search anything...',
                        style: TextStyle(color: Colors.grey[400])),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildIconButton(Icons.chat_bubble_outline),
              const SizedBox(width: 12),
              _buildIconButton(Icons.notifications_none),
              const SizedBox(width: 16),
              const CircleAvatar(
                radius: 20,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?u=admin'),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Icon(icon, size: 20, color: Colors.grey[600]),
    );
  }

  Widget _buildStatsGrid(DashboardStats stats, bool isMobile, bool isDesktop) {
    return LayoutBuilder(builder: (context, constraints) {
      double childAspectRatio = isDesktop ? 2.5 : (isMobile ? 2.5 : 2.0);
      return GridView.count(
        crossAxisCount: isDesktop ? 4 : (isMobile ? 1 : 2),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: childAspectRatio,
        children: [
          _buildStatCard(
            'Customers',
            stats.totalUsers.toString(),
            '${stats.userGrowth.toStringAsFixed(1)}%',
            stats.userGrowth >= 0,
            Icons.people_outline,
            const Color(0xFF6C5DD3),
          ),
          _buildStatCard(
            'Revenue',
            '₹${(stats.totalRevenue / 1000).toStringAsFixed(1)}k',
            '${stats.revenueGrowth.toStringAsFixed(1)}%',
            stats.revenueGrowth >= 0,
            Icons.account_balance_wallet_outlined,
            const Color(0xFF4DB6AC),
          ),
          _buildStatCard(
            'Completion',
            '${((stats.orderStatusCounts['completed'] ?? 0) / (stats.totalOrders > 0 ? stats.totalOrders : 1) * 100).toStringAsFixed(0)}%',
            '-0.2%',
            false,
            Icons.check_circle_outline,
            const Color(0xFFFFAB91),
          ),
          _buildStatCard(
            'Orders',
            stats.totalOrders.toString(),
            '${stats.orderGrowth.toStringAsFixed(1)}%',
            stats.orderGrowth >= 0,
            Icons.description_outlined,
            const Color(0xFF64B5F6),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(String title, String value, String growth,
      bool isPositive, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B39))),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    growth,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Since last week',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ],
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceStatistics(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(28),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order Statistics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        value:
                            (stats.orderStatusCounts['paid'] ?? 0).toDouble(),
                        color: const Color(0xFF6C5DD3),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (stats.orderStatusCounts['pending'] ?? 0)
                            .toDouble(),
                        color: const Color(0xFF1E1B39),
                        radius: 20,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (stats.orderStatusCounts['overdue'] ?? 0)
                            .toDouble(),
                        color: Colors.grey[200],
                        radius: 20,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(stats.totalOrders.toString(),
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const Text('Total Orders',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildStatusRow(
              'Total Paid',
              stats.orderStatusCounts['paid'].toString(),
              const Color(0xFF1E1B39)),
          _buildStatusRow(
              'Total Pending',
              stats.orderStatusCounts['pending'].toString(),
              const Color(0xFF6C5DD3)),
          _buildStatusRow('Total Overdue',
              stats.orderStatusCounts['overdue'].toString(), Colors.grey[300]!),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
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
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSalesAnalytics(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(28),
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sales Analytics',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[100], strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
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
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: stats.monthlyRevenue.values
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value / 1000))
                        .toList(),
                    isCurved: true,
                    color: const Color(0xFF6C5DD3),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFF6C5DD3),
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6C5DD3).withOpacity(0.1),
                          const Color(0xFF6C5DD3).withOpacity(0.0)
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentInvoices(DashboardStats stats, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Orders',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text('Filter',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile)
            ...stats.recentOrders.map((order) => _buildOrderMobileItem(order))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(0.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1.5),
                4: FlexColumnWidth(1.2),
                5: FlexColumnWidth(0.8),
                6: FlexColumnWidth(0.8),
              },
              children: [
                _buildTableHeader(),
                ...stats.recentOrders
                    .asMap()
                    .entries
                    .map((entry) => _buildTableRow(entry.key + 1, entry.value)),
              ],
            ),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('ID Order',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Customer',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Services',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Order Date',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Status',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('Price',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)))),
      ],
    );
  }

  TableRow _buildTableRow(int index, Map<String, dynamic> order) {
    return TableRow(
      decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey[50]!))),
      children: [
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(index.toString(),
                    style: const TextStyle(fontSize: 13)))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('#${order['id'].toString().substring(0, 6)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)))),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundImage: order['customerImage'] != null
                    ? NetworkImage(order['customerImage'])
                    : null,
                child: order['customerImage'] == null
                    ? const Icon(Icons.person, size: 14)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(order['customerName'],
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500))),
            ],
          ),
        )),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(order['items'],
                    style: const TextStyle(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis))),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child:
                    Text(order['date'], style: const TextStyle(fontSize: 13)))),
        TableCell(
            child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _buildStatusBadge(order['status']),
        )),
        TableCell(
            child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('₹${order['price'].toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)))),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'delivered':
        bgColor = const Color(0xFFE8F5E9);
        textColor = Colors.green;
        break;
      case 'pending':
      case 'confirmed':
        bgColor = const Color(0xFFFFF3E0);
        textColor = Colors.orange;
        break;
      case 'cancelled':
      case 'overdue':
        bgColor = const Color(0xFFFFEBEE);
        textColor = Colors.red;
        break;
      default:
        bgColor = const Color(0xFFF3F3F9);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              color: textColor, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildOrderMobileItem(Map<String, dynamic> order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFBFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('#${order['id'].toString().substring(0, 6)}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              _buildStatusBadge(order['status']),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: order['customerImage'] != null
                    ? NetworkImage(order['customerImage'])
                    : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order['customerName'],
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(order['date'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const Spacer(),
              Text('₹${order['price'].toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:cloud_admin/features/users/data/users_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DashboardStats {
  final int totalUsers;
  final int totalOrders;
  final double totalRevenue;
  final int activeVendors;
  final int totalCategories;
  final int totalSubCategories;
  final int totalServices;
  final Map<String, double> monthlyRevenue;
  final List<Map<String, dynamic>> recentUsers;
  final List<Map<String, dynamic>> servicePerformance;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> subCategories;
  final List<Map<String, dynamic>> services;
  final Map<String, int> orderStatusCounts;
  final List<Map<String, dynamic>> recentOrders;
  final double userGrowth;
  final double revenueGrowth;
  final double orderGrowth;

  // New metrics for Analytics comparison
  final int lastMonthUsers;
  final int lastMonthOrders;
  final double lastMonthRevenue;
  final int cancelledOrders;
  final int lastMonthCancelled;
  final Map<String, int> monthlyOrders;

  DashboardStats({
    required this.totalUsers,
    required this.totalOrders,
    required this.totalRevenue,
    required this.activeVendors,
    required this.totalCategories,
    required this.totalSubCategories,
    required this.totalServices,
    required this.monthlyRevenue,
    required this.recentUsers,
    required this.servicePerformance,
    required this.categories,
    required this.subCategories,
    required this.services,
    required this.orderStatusCounts,
    required this.recentOrders,
    required this.monthlyOrders,
    this.userGrowth = 0.0,
    this.revenueGrowth = 0.0,
    this.orderGrowth = 0.0,
    this.lastMonthUsers = 0,
    this.lastMonthOrders = 0,
    this.lastMonthRevenue = 0.0,
    this.cancelledOrders = 0,
    this.lastMonthCancelled = 0,
  });
}

final dashboardOrdersProvider =
    StreamProvider<List<QueryDocumentSnapshot>>((ref) {
  // Query all orders from all users using collection group
  return FirebaseFirestore.instance
      .collectionGroup('orders')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs);
});

final dashboardCategoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('categories').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final dashboardSubCategoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('subCategories').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final dashboardServicesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return FirebaseFirestore.instance.collection('services').snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

final dashboardStatsProvider = Provider<AsyncValue<DashboardStats>>((ref) {
  final usersAsync = ref.watch(usersProvider);
  final ordersAsync = ref.watch(dashboardOrdersProvider);
  final categoriesAsync = ref.watch(dashboardCategoriesProvider);
  final subCategoriesAsync = ref.watch(dashboardSubCategoriesProvider);
  final servicesAsync = ref.watch(dashboardServicesProvider);

  if (usersAsync is AsyncData &&
      ordersAsync is AsyncData &&
      categoriesAsync is AsyncData &&
      subCategoriesAsync is AsyncData &&
      servicesAsync is AsyncData) {
    final users = usersAsync.value!;
    final ordersDocs = ordersAsync.value!;
    final categories = categoriesAsync.value!;
    final subCategories = subCategoriesAsync.value!;
    final services = servicesAsync.value!;

    double totalRevenue = 0;
    Map<String, double> monthlyRev = {};
    Map<String, int> monthlyOrders = {};
    Map<String, int> serviceCounts = {};
    Map<String, int> statusCounts = {
      'paid': 0,
      'pending': 0,
      'completed': 0,
      'overdue': 0
    };

    final now = DateTime.now();
    final firstDayThisMonth = DateTime(now.year, now.month, 1);
    final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);

    int currentMonthOrders = 0;
    double currentMonthRevenue = 0;
    int lastMonthOrders = 0;
    double lastMonthRevenue = 0;
    int cancelledCount = 0;
    int lastMonthCancelled = 0;

    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(date);
      monthlyRev[key] = 0.0;
      monthlyOrders[key] = 0;
    }

    final recentOrdersList = <Map<String, dynamic>>[];

    for (var doc in ordersDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] as String?)?.toLowerCase() ?? 'pending';
      final total = (data['priceSummary']?['total'] ?? 0).toDouble();

      // Update status counts for chart
      if (status == 'completed' || status == 'delivered') {
        statusCounts['paid'] = (statusCounts['paid'] ?? 0) + 1;
      } else if (status == 'pending' || status == 'confirmed') {
        statusCounts['pending'] = (statusCounts['pending'] ?? 0) + 1;
      } else {
        statusCounts['overdue'] = (statusCounts['overdue'] ?? 0) + 1;
      }

      if (status == 'cancelled') cancelledCount++;

      final createdAtValue = data['createdAt'];
      DateTime? createdAtDate;
      if (createdAtValue != null) {
        // Handle Firestore Timestamp
        if (createdAtValue is Timestamp) {
          createdAtDate = createdAtValue.toDate();
        } else if (createdAtValue is String) {
          createdAtDate = DateTime.tryParse(createdAtValue);
        } else if (createdAtValue is Map &&
            createdAtValue.containsKey('_seconds')) {
          final seconds = createdAtValue['_seconds'] as int;
          final nanoseconds = createdAtValue['_nanoseconds'] as int? ?? 0;
          createdAtDate = DateTime.fromMillisecondsSinceEpoch(
            seconds * 1000 + (nanoseconds / 1000000).floor(),
          );
        }
      }

      if (createdAtDate != null) {
        final monthKey = DateFormat('MMM').format(createdAtDate);
        if (monthlyRev.containsKey(monthKey)) {
          if (status == 'completed' || status == 'delivered') {
            monthlyRev[monthKey] = (monthlyRev[monthKey] ?? 0) + total;
          }
          monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
        }

        // Current Month vs Last Month calculations
        if (createdAtDate.isAfter(firstDayThisMonth)) {
          currentMonthOrders++;
          if (status == 'completed' || status == 'delivered') {
            currentMonthRevenue += total;
          }
        } else if (createdAtDate.isAfter(firstDayLastMonth) &&
            createdAtDate.isBefore(firstDayThisMonth)) {
          lastMonthOrders++;
          if (status == 'completed' || status == 'delivered') {
            lastMonthRevenue += total;
          }
          if (status == 'cancelled') lastMonthCancelled++;
        }
      }

      if (status == 'completed' || status == 'delivered') {
        totalRevenue += total;
      }

      // Collect recent orders for table
      if (recentOrdersList.length < 10) {
        recentOrdersList.add({
          'id': doc.id,
          'customerName': data['user']?['name'] ?? 'Walk-in',
          'customerImage': data['user']?['image'],
          'items':
              (data['services'] as List?)?.map((s) => s['name']).join(', ') ??
                  'Service',
          'date': createdAtDate != null
              ? DateFormat('dd MMM yyyy').format(createdAtDate)
              : 'Unknown',
          'status': status,
          'price': total,
          'category': data['category'] ?? 'General',
        });
      }

      final items = data['services'] as List?;
      if (items != null) {
        for (var s in items) {
          final name = s['name'] ?? 'General';
          serviceCounts[name] = (serviceCounts[name] ?? 0) + 1;
        }
      }
    }

    // User growth
    int currentMonthUsers = 0;
    int lastMonthUsers = 0;
    for (var u in users) {
      final createdAt = u.createdAt;
      if (createdAt != null) {
        if (createdAt.isAfter(firstDayThisMonth)) {
          currentMonthUsers++;
        } else if (createdAt.isAfter(firstDayLastMonth) &&
            createdAt.isBefore(firstDayThisMonth)) {
          lastMonthUsers++;
        }
      }
    }

    final sortedServices = serviceCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final servicePerformance = sortedServices.take(5).map((e) {
      return {
        'name': e.key,
        'count': e.value,
        'progress': (e.value / (ordersDocs.isEmpty ? 1 : ordersDocs.length))
            .clamp(0.0, 1.0),
      };
    }).toList();

    return AsyncValue.data(DashboardStats(
      totalUsers: users.length,
      totalOrders: ordersDocs.length,
      totalRevenue: totalRevenue,
      activeVendors: users.where((u) => u.role == 'vendor').length,
      totalCategories: categories.length,
      totalSubCategories: subCategories.length,
      totalServices: services.length,
      monthlyRevenue: monthlyRev,
      monthlyOrders: monthlyOrders,
      recentUsers: users
          .take(5)
          .map((u) => {
                'name': u.name,
                'image': u.profileImage,
                'role': u.role,
              })
          .toList(),
      servicePerformance: servicePerformance,
      categories: categories,
      subCategories: subCategories,
      services: services,
      orderStatusCounts: statusCounts,
      recentOrders: recentOrdersList,
      lastMonthUsers: lastMonthUsers,
      lastMonthOrders: lastMonthOrders,
      lastMonthRevenue: lastMonthRevenue,
      cancelledOrders: cancelledCount,
      lastMonthCancelled: lastMonthCancelled,
      userGrowth: lastMonthUsers == 0
          ? 100
          : ((currentMonthUsers - lastMonthUsers) / lastMonthUsers) * 100,
      revenueGrowth: lastMonthRevenue == 0
          ? 100
          : ((currentMonthRevenue - lastMonthRevenue) / lastMonthRevenue) * 100,
      orderGrowth: lastMonthOrders == 0
          ? 100
          : ((currentMonthOrders - lastMonthOrders) / lastMonthOrders) * 100,
    ));
  }

  if (usersAsync is AsyncError)
    return AsyncValue.error(usersAsync.error!, usersAsync.stackTrace!);
  if (ordersAsync is AsyncError)
    return AsyncValue.error(ordersAsync.error!, ordersAsync.stackTrace!);

  return const AsyncValue.loading();
});

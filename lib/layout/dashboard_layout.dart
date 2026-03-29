import 'dart:convert';
import 'package:cloud_admin/shared/widgets/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_admin/core/services/socket_service.dart';

class DashboardLayout extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardLayout({super.key, required this.child});

  @override
  ConsumerState<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends ConsumerState<DashboardLayout> {
  @override
  void initState() {
    super.initState();
    // Initialize Notification Listener globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.init();
      socketService.onNewOrder((data) {
        if (mounted) {
          final location = GoRouterState.of(context).uri.toString();
          // If we are on the bookings page, do NOT show the popup (as requested)
          // and do NOT start infinite ringing (to avoid ghost sound).
          if (location == '/bookings') {
            return;
          }

          socketService.startRinging();
          _showNewOrderDialog(context, data);
        }
      });
    });
  }

  void _showNewOrderDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.notifications_active,
                color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Text('New Booking Received!'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order #${data['orderNumber']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              Text('Customer: ${data['customerName']}'),
              Text('Total Amount: ₹${data['amount']}'),
              const SizedBox(height: 10),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...(data['services'] as List)
                  .map<Widget>((s) => Text('• ${s['name']}'))
                  .toList(),
              const SizedBox(height: 20),
              const Text('Please review this order in the Bookings section.',
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(socketServiceProvider).stopRinging(); // Stop Sound
              Navigator.pop(context); // Close dialog
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(socketServiceProvider).stopRinging(); // Stop Sound
              Navigator.pop(context); // Close dialog
              context.go('/bookings'); // Navigate to bookings
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            const Sidebar(),
            Expanded(
              child: Column(
                children: [
                  const _DashboardHeader(showMenuButton: false),
                  Expanded(
                    child: widget.child,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: _DashboardHeader(showMenuButton: true),
        ),
        drawer: const Sidebar(),
        body: widget.child,
      );
    }
  }
}

class _DashboardHeader extends StatefulWidget {
  final bool showMenuButton;
  const _DashboardHeader({required this.showMenuButton});

  @override
  State<_DashboardHeader> createState() => _DashboardHeaderState();
}

class _DashboardHeaderState extends State<_DashboardHeader> {
  String _adminName = 'Admin';
  String _adminRole = 'Administrator';
  String? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final prefs = await SharedPreferences.getInstance();
    final adminDataString = prefs.getString('admin_data');
    if (adminDataString != null) {
      final data = json.decode(adminDataString);
      if (mounted) {
        setState(() {
          _adminName = data['name'] ?? 'Admin';
          _adminRole = data['role'] ?? 'Administrator';
          _profileImage = data['profileImage'];
        });
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      context.go('/login');
    }
  }

  String _getTitle(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.toString();
      if (location == '/') return 'Dashboard';
      if (location == '/users') return 'User Management';
      if (location == '/bookings') return 'Booking Management';
      if (location == '/services') return 'Services Management';
      if (location == '/services/add') return 'Add New Service';
      if (location == '/analytics') return 'Analytics';
      if (location == '/categories') return 'Category Management';
      if (location == '/categories/add') return 'Add New Category';
      if (location == '/sub-categories') return 'Sub Category Management';
      if (location == '/sub-categories/add') return 'Add Sub Category';
      if (location == '/banners') return 'Banner Management';
      if (location == '/banners/add') return 'Add New Banner';
      if (location == '/notifications') return 'Notifications';
      if (location == '/notifications/add') return 'Send Notification';
      if (location == '/cities') return 'Country Management';
      if (location == '/cities/add') return 'Add New City';
      if (location == '/addons') return 'Add-ons Management';
      if (location == '/addons/add') return 'Add New Add-on';
      if (location == '/testimonials') return 'Testimonials';
      if (location == '/profile') return 'My Profile';
      if (location == '/webbox') return 'Web Home Page Content';

      if (location.startsWith('/')) {
        final simplified = location.substring(1).replaceAll('/', ' ');
        return simplified.isEmpty
            ? 'Dashboard'
            : simplified[0].toUpperCase() + simplified.substring(1);
      }
      return 'Dashboard';
    } catch (e) {
      return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (widget.showMenuButton)
            IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          Expanded(
            child: Text(
              _getTitle(context),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          const Spacer(),
          Flexible(
            fit: FlexFit.loose,
            child: InkWell(
              onTap: () async {
                await context.push('/profile');
                _loadAdminData(); // Refresh on return
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        _profileImage != null && _profileImage!.isNotEmpty
                            ? NetworkImage(_profileImage!)
                            : null,
                    backgroundColor: Colors.blue.shade100,
                    child: (_profileImage == null || _profileImage!.isEmpty)
                        ? Text(
                            _adminName.isNotEmpty
                                ? _adminName[0].toUpperCase()
                                : 'A',
                            style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  if (MediaQuery.of(context).size.width > 600)
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _adminName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            _adminRole,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }
}

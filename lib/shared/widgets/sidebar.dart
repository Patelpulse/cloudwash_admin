import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.sidebarColor,
      child: Column(
        children: [
          // Logo Area
          Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            child: const Text(
              'CLOUDWASH ADMIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(color: Colors.white10),
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  path: '/',
                ),
                _SidebarItem(
                  icon: Icons.people_outline,
                  title: 'Users',
                  path: '/users',
                ),
                _SidebarItem(
                  icon: Icons.calendar_today_outlined,
                  title: 'Bookings',
                  path: '/bookings',
                ),
                _SidebarItem(
                  icon: Icons.analytics_outlined,
                  title: 'Analytics',
                  path: '/analytics',
                ),
                _SectionHeader(title: 'CONTENT MANAGEMENT'),
                _SidebarItem(
                  icon: Icons.category_outlined,
                  title: 'Categories',
                  path: '/categories',
                ),
                _SidebarItem(
                  icon: Icons.grid_view_outlined,
                  title: 'Sub-Categories',
                  path: '/sub-categories',
                ),
                _SidebarItem(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Services',
                  path: '/services',
                ),
                _SidebarItem(
                  icon: Icons.image_outlined,
                  title: 'Banners',
                  path: '/banners',
                ),
                _SidebarItem(
                  icon: Icons.reviews_outlined,
                  title: 'Testimonials',
                  path: '/testimonials',
                ),
                _SidebarItem(
                  icon: Icons.web,
                  title: 'Web Home Page',
                  path: '/web-landing',
                ),
                _SectionHeader(title: 'SYSTEM'),
                _SidebarItem(
                  icon: Icons.location_city_outlined,
                  title: 'Cities',
                  path: '/cities',
                ),
                _SidebarItem(
                  icon: Icons.extension_outlined,
                  title: 'Add-ons',
                  path: '/addons',
                ),
                _SidebarItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  path: '/notifications',
                ),
                _SidebarItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  path: '/profile',
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarItem(
              icon: Icons.logout,
              title: 'Logout',
              path: '/logout', // Not used for navigation but consistent UI
              onTap: () => _logout(context),
              isDestructive: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String path;
  final VoidCallback? onTap;
  final bool isDestructive;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.path,
    this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    // Basic active state check logic
    final String location = GoRouterState.of(context).uri.toString();
    final bool isActive = location == path && !isDestructive;

    final color = isDestructive
        ? Colors.redAccent
        : (isActive ? Colors.white : Colors.white70);
    final bgColor = isActive ? AppTheme.primaryBlue : Colors.transparent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: color,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          // Close drawer if on mobile
          if (Scaffold.maybeOf(context)?.hasDrawer ?? false) {
            Navigator.pop(context);
          }
          if (onTap != null) {
            onTap!();
          } else {
            context.go(path);
          }
        },
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

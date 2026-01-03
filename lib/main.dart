import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/addons/screens/add_addon_screen.dart';
import 'package:cloud_admin/features/addons/screens/addons_screen.dart';
import 'package:cloud_admin/features/auth/screens/login_screen.dart';
import 'package:cloud_admin/features/banners/screens/add_banner_screen.dart';
import 'package:cloud_admin/features/banners/screens/banners_screen.dart';
import 'package:cloud_admin/features/categories/screens/add_category_screen.dart';
import 'package:cloud_admin/features/categories/screens/categories_screen.dart';
import 'package:cloud_admin/features/cities/screens/add_city_screen.dart';
import 'package:cloud_admin/features/cities/screens/cities_screen.dart';
import 'package:cloud_admin/features/dashboard/screens/dashboard_screen.dart';
import 'package:cloud_admin/features/analytics/screens/analytics_screen.dart';
import 'package:cloud_admin/features/bookings/screens/bookings_screen.dart';
import 'package:cloud_admin/features/notifications/screens/add_notification_screen.dart';
import 'package:cloud_admin/features/notifications/screens/notifications_screen.dart';
import 'package:cloud_admin/features/profile/screens/profile_screen.dart';
import 'package:cloud_admin/features/services/screens/add_service_screen.dart';
import 'package:cloud_admin/features/services/screens/services_screen.dart';
import 'package:cloud_admin/features/sub_categories/screens/add_sub_category_screen.dart';
import 'package:cloud_admin/features/sub_categories/screens/sub_categories_screen.dart';
import 'package:cloud_admin/features/testimonials/screens/testimonials_screen.dart';
import 'package:cloud_admin/features/users/screens/users_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/edit_about_us_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/edit_hero_section_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/edit_stats_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/edit_testimonials_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/edit_why_choose_us_screen.dart';
import 'package:cloud_admin/features/web_landing/screens/web_landing_screen.dart';
import 'package:cloud_admin/layout/dashboard_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  runApp(ProviderScope(child: CloudAdminApp(isLoggedIn: isLoggedIn)));
}

class CloudAdminApp extends StatefulWidget {
  final bool isLoggedIn;
  const CloudAdminApp({super.key, this.isLoggedIn = false});

  @override
  State<CloudAdminApp> createState() => _CloudAdminAppState();
}

class _CloudAdminAppState extends State<CloudAdminApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = GoRouter(
      initialLocation: widget.isLoggedIn ? '/' : '/login',
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          pageBuilder: (context, state, child) {
            return NoTransitionPage(
              child: DashboardLayout(child: child),
            );
          },
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersScreen(),
            ),
            GoRoute(
              path: '/bookings',
              builder: (context, state) => const BookingsScreen(),
            ),
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final categoryToEdit = state.extra as Map<String, dynamic>?;
                    return AddCategoryScreen(categoryToEdit: categoryToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/banners',
              builder: (context, state) => const BannersScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final bannerToEdit = state.extra as Map<String, dynamic>?;
                    return AddBannerScreen(bannerToEdit: bannerToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/sub-categories',
              builder: (context, state) => const SubCategoriesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final subCategoryToEdit =
                        state.extra as Map<String, dynamic>?;
                    return AddSubCategoryScreen(
                        subCategoryToEdit: subCategoryToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/notifications',
              builder: (context, state) => const NotificationsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final notificationToEdit =
                        state.extra as Map<String, dynamic>?;
                    return AddNotificationScreen(
                        notificationToEdit: notificationToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/services',
              builder: (context, state) => const ServicesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final serviceToEdit = state.extra as Map<String, dynamic>?;
                    return AddServiceScreen(serviceToEdit: serviceToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/cities',
              builder: (context, state) => const CitiesScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final cityToEdit = state.extra as Map<String, dynamic>?;
                    return AddCityScreen(cityToEdit: cityToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/addons',
              builder: (context, state) => const AddonsScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) {
                    final addonToEdit = state.extra as Map<String, dynamic>?;
                    return AddAddonScreen(addonToEdit: addonToEdit);
                  },
                ),
              ],
            ),
            GoRoute(
              path: '/testimonials',
              builder: (context, state) => const TestimonialsScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/web-landing',
              builder: (context, state) => const WebLandingScreen(),
              routes: [
                GoRoute(
                  path: 'hero',
                  builder: (context, state) => const EditHeroSectionScreen(),
                ),
                GoRoute(
                  path: 'about',
                  builder: (context, state) => const EditAboutUsScreen(),
                ),
                GoRoute(
                  path: 'stats',
                  builder: (context, state) => const EditStatsScreen(),
                ),
                GoRoute(
                  path: 'testimonials',
                  builder: (context, state) => const EditTestimonialsScreen(),
                ),
                GoRoute(
                  path: 'why-choose-us',
                  builder: (context, state) => const EditWhyChooseUsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Urban Admin',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

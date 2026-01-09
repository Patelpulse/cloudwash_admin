import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/users/data/users_provider.dart';
import 'package:cloud_admin/features/users/data/user_admin_model.dart';
import 'package:cloud_admin/features/users/widgets/user_list_item.dart';
import 'package:cloud_admin/features/users/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final userSearchProvider = StateProvider<String>((ref) => '');

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: usersAsync.when(
        data: (users) {
          debugPrint('DEBUG: UsersScreen received ${users.length} users');
          final total = users.length;
          final active = users.where((u) => u.isVerified).length;
          final blocked = users.where((u) => !u.isVerified).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsRow(context, total, active, blocked),
                const SizedBox(height: 32),
                _buildSearchBar(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'All Users ($total)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildFirebaseBadge(),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => ref.invalidate(usersProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (users.isEmpty)
                  _buildEmptyState()
                else if (_filterUsers(users, ref.watch(userSearchProvider))
                    .isEmpty)
                  const Center(child: Text("No users found matching search."))
                else
                  ..._filterUsers(users, ref.watch(userSearchProvider))
                      .map((user) => UserListItem(
                            name: user.name,
                            email: user.email,
                            phone: user.phone,
                            imageUrl: user.profileImage,
                            status: 'Active', // Default
                            joinedDate:
                                'Joined ${DateFormat('MM/dd/yyyy').format(user.createdAt)}',
                            onDelete: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete User'),
                                  content: Text(
                                      'Are you sure you want to delete ${user.name}?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await ref
                                      .read(usersRepositoryProvider)
                                      .deleteUser(user.id);
                                  ref.refresh(usersProvider);
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')));
                                  }
                                }
                              }
                            },
                            onTap: () => _showUserDetails(context, user),
                          )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatsRow(
      BuildContext context, int total, int active, int blocked) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 800) crossAxisCount = 1;

        if (crossAxisCount == 1) {
          return Column(
            children: [
              UserStatsCard(
                label: 'Total Users',
                value: total.toString(),
                icon: Icons.people,
                color: Colors.indigo,
              ),
              const SizedBox(height: 16),
              UserStatsCard(
                label: 'Active',
                value: active.toString(),
                icon: Icons.check_circle,
                color: AppTheme.successGreen,
              ),
              const SizedBox(height: 16),
              UserStatsCard(
                label: 'Blocked',
                value: blocked.toString(),
                icon: Icons.block,
                color: Colors.pink,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: UserStatsCard(
                label: 'Total Users',
                value: total.toString(),
                icon: Icons.people,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: UserStatsCard(
                label: 'Active',
                value: active.toString(),
                icon: Icons.check_circle,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: UserStatsCard(
                label: 'Blocked',
                value: blocked.toString(),
                icon: Icons.block,
                color: Colors.pink,
              ),
            ),
          ],
        );
      },
    );
  }

  List<UserAdminModel> _filterUsers(List<UserAdminModel> users, String query) {
    if (query.isEmpty) return users;
    final lowerQuery = query.toLowerCase();
    return users.where((user) {
      return user.name.toLowerCase().contains(lowerQuery) ||
          user.email.toLowerCase().contains(lowerQuery) ||
          user.phone.contains(query);
    }).toList();
  }

  Widget _buildSearchBar() {
    return Consumer(builder: (context, ref, child) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: TextField(
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.grey),
          ),
          onChanged: (value) {
            ref.read(userSearchProvider.notifier).state = value;
          },
        ),
      );
    });
  }

  void _showUserDetails(BuildContext context, UserAdminModel user) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'User Details',
      pageBuilder: (context, _, __) => _UserDetailsModal(user: user),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim, _, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
    );
  }

  Widget _buildFirebaseBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[100]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_done, size: 14, color: Colors.green[700]),
          const SizedBox(width: 4),
          Text(
            'Firebase Live',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "No users found in Firebase Firestore.",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              "Make sure users have signed up in the mobile app.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDetailsModal extends ConsumerWidget {
  final UserAdminModel user;

  const _UserDetailsModal({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider(user.id));
    final ordersAsync = ref.watch(userOrdersProvider(user.id));

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 500,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 40,
                offset: const Offset(-10, 0),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F4F6),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Details',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${user.id.substring(0, 8)}...',
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: user.profileImage != null
                              ? NetworkImage(user.profileImage!)
                              : null,
                          child: user.profileImage == null
                              ? Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Stats Section
                      statsAsync.when(
                        data: (stats) => Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                  'Total Orders',
                                  stats['totalOrders'].toString(),
                                  Icons.shopping_bag_outlined,
                                  Colors.orange),
                              Container(
                                  width: 1,
                                  height: 40,
                                  color: Colors.grey.shade300),
                              _buildStatItem(
                                  'Total Spent',
                                  '₹${stats['totalSpend'].toStringAsFixed(0)}',
                                  Icons.payments_outlined,
                                  Colors.green),
                            ],
                          ),
                        ),
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) =>
                            const Center(child: Text('Error loading stats')),
                      ),

                      const SizedBox(height: 32),

                      _detailRow(Icons.email_outlined, 'Email', user.email),
                      const Divider(height: 32),
                      _detailRow(Icons.phone_outlined, 'Phone', user.phone),
                      const Divider(height: 32),
                      _detailRow(Icons.calendar_today_outlined, 'Joined',
                          DateFormat('MMMM dd, yyyy').format(user.createdAt)),
                      const Divider(height: 32),
                      _detailRow(Icons.verified_user_outlined, 'Status',
                          'Active (Verified)'),

                      const SizedBox(height: 32),

                      // Recent Orders Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Orders',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Go to bookings screen with filter maybe?
                              // For now just close and stay simple
                            },
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ordersAsync.when(
                        data: (orders) {
                          if (orders.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No orders found for this user',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length > 5 ? 5 : orders.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              final status = order['status'] ?? 'pending';
                              final total =
                                  order['priceSummary']?['total'] ?? 0;
                              final date = order['createdAt'];

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status)
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getStatusIcon(status),
                                        color: _getStatusColor(status),
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Order #${order['orderNumber'] ?? order['id'].toString().substring(0, 6)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            date != null
                                                ? DateFormat('MMM dd, yyyy')
                                                    .format(
                                                        DateTime.parse(date))
                                                : 'Recent',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹$total',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Center(child: Text('Error: $err')),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF3F4F6))),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _confirmDelete(context, ref),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(usersRepositoryProvider).deleteUser(user.id);
        ref.refresh(usersProvider);
        if (context.mounted) {
          Navigator.pop(context); // Close sidebar
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('User deleted')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.grey.shade700, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'confirmed':
        return Colors.blue;
      case 'in-progress':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.access_time;
      case 'cancelled':
        return Icons.cancel;
      case 'confirmed':
        return Icons.thumb_up;
      case 'in-progress':
        return Icons.work;
      default:
        return Icons.help;
    }
  }
}
